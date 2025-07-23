require 'votd'
require 'httparty'
require 'json'
require 'date'
require 'dotenv/load'

require 'kramdown'

# --- Configuration ---
ANTHROPIC_API_KEY = ENV['ANTHROPIC_API_KEY']
API_URL = 'https://api.anthropic.com/v1/messages'
MODEL = 'claude-sonnet-4-20250514'
MAX_TOKENS = 1500

PROMPT_TEMPLATE_PATH = 'templates/devotional_prompt.txt'
HTML_TEMPLATE_PATH = 'templates/devotional_template.html'
DEV_HTML_PATH = 'dev.html'
VERSES_DIR = 'verses'

# Simple struct for verse data
Verse = Struct.new(:text, :reference, :version)

# --- Helper Functions (reused from main script) ---

def load_cached_verse(date)
  verse_file = File.join(VERSES_DIR, "#{date.strftime('%Y-%m-%d')}.json")
  return nil unless File.exist?(verse_file)
  
  begin
    data = JSON.parse(File.read(verse_file))
    if data['date'] && data['reference'] && data['text'] && data['version']
      puts "Using cached verse for #{date.strftime('%Y-%m-%d')}"
      return {
        text: data['text'],
        reference: data['reference'],
        version: data['version']
      }
    end
  rescue JSON::ParserError => e
    puts "Error parsing cached verse file: #{e.message}"
  rescue => e
    puts "Error loading cached verse: #{e.message}"
  end
  
  nil
end

def save_verse_to_cache(date, verse)
  Dir.mkdir(VERSES_DIR) unless Dir.exist?(VERSES_DIR)
  
  verse_data = {
    date: date.strftime('%Y-%m-%d'),
    reference: verse.reference,
    text: verse.text,
    version: 'ESV',
    fetched_at: Time.now.iso8601
  }
  
  verse_file = File.join(VERSES_DIR, "#{date.strftime('%Y-%m-%d')}.json")
  File.write(verse_file, JSON.pretty_generate(verse_data))
  puts "Cached verse for #{date.strftime('%Y-%m-%d')}"
rescue => e
  puts "Error saving verse to cache: #{e.message}"
end

def fetch_verse_from_api
  votd = Votd::BibleGateway.new(:esv)
  votd
rescue => e
  puts "Error fetching verse from API: #{e.message}"
  nil
end

def get_or_fetch_verse(date = Date.today)
  # First, try to load from cache
  cached_verse = load_cached_verse(date)
  if cached_verse
    return Verse.new(cached_verse[:text], cached_verse[:reference], cached_verse[:version])
  end
  
  # If not cached, fetch from API
  verse = fetch_verse_from_api
  if verse
    save_verse_to_cache(date, verse)
    return verse
  end
  
  # If API failed, try yesterday's cached verse
  puts "API fetch failed. Trying yesterday's cached verse."
  yesterday_cached = load_cached_verse(date - 1)
  if yesterday_cached
    puts "Using yesterday's cached verse as fallback"
    return Verse.new(yesterday_cached[:text], yesterday_cached[:reference], yesterday_cached[:version])
  end
  
  nil
end

def generate_devotional(verse_text, verse_reference)
  prompt_template = File.read(PROMPT_TEMPLATE_PATH)
  prompt = prompt_template.gsub('{{VERSE_REFERENCE}}', verse_reference)
                          .gsub('{{VERSE_TEXT}}', verse_text)

  headers = {
    'Content-Type' => 'application/json',
    'x-api-key' => ANTHROPIC_API_KEY,
    'anthropic-version' => '2023-06-01'
  }

  body = {
    model: MODEL,
    max_tokens: MAX_TOKENS,
    messages: [{ role: 'user', content: prompt }]
  }.to_json

  response = HTTParty.post(API_URL, headers: headers, body: body, timeout: 120)

  if response.code == 200
    JSON.parse(response.body)['content'][0]['text']
  else
    puts "API Error: #{response.code} - #{response.body}"
    nil
  end
rescue => e
  puts "Error calling Claude API: #{e.message}"
  nil
end

def process_template(template_path, replacements)
  template = File.read(template_path)
  replacements.each do |placeholder, value|
    template.gsub!("{{#{placeholder}}}", value.to_s)
  end
  template
end

# --- Development Script Logic ---

puts "=== Development Devotional Generator ==="

# 1. Get Verse (using cache-first approach)
verse = get_or_fetch_verse
unless verse
  puts "Could not retrieve verse from cache or API, and no fallback available. Exiting."
  exit 1
end

puts "Verse for development: #{verse.reference} - #{verse.text}"

# 2. Generate Devotional
puts "Generating devotional content..."
devotional_content = generate_devotional(verse.text, verse.reference)
unless devotional_content
  puts "Devotional generation failed. Using verse only."
  devotional_content = "<p>We apologize, but we couldn't generate the devotional content for today. Please reflect on the verse below.</p>"
end

# 3. Create development HTML
today_date_formatted = Date.today.strftime('%B %d, %Y')
replacements = {
  'PAGE_TITLE' => "Development Devotional for #{today_date_formatted}",
  'DATE_FORMATTED' => today_date_formatted,
  'VERSE_REFERENCE' => verse.reference,
  'VERSE_TEXT' => verse.text,
  'DEVOTIONAL_CONTENT' => Kramdown::Document.new(devotional_content).to_html
}

dev_html_content = process_template(HTML_TEMPLATE_PATH, replacements)
File.write(DEV_HTML_PATH, dev_html_content)
puts "Created development devotional: #{DEV_HTML_PATH}"

puts "=== Development devotional generation complete ==="