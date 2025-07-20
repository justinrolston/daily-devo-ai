require 'votd'
require 'httparty'
require 'json'
require 'date'

require 'kramdown'

# --- Configuration ---
ANTHROPIC_API_KEY = ENV['ANTHROPIC_API_KEY']
API_URL = 'https://api.anthropic.com/v1/messages'
MODEL = 'claude-sonnet-4-20250514'
MAX_TOKENS = 1500

PROMPT_TEMPLATE_PATH = 'templates/devotional_prompt.txt'
HTML_TEMPLATE_PATH = 'templates/devotional_template.html'
TODAY_HTML_PATH = 'today.html'
ARCHIVE_DIR = 'devotionals'

# --- Helper Functions ---

def get_verse_of_the_day
  votd = Votd::BibleGateway.new(:esv)
  votd
rescue => e
  puts "Error fetching verse: #{e.message}"
  nil
end

def get_previous_verse
  # Fallback: read from yesterday's file if it exists
  yesterday_file = File.join(ARCHIVE_DIR, "#{(Date.today - 1).strftime('%Y-%m-%d')}.html")
  if File.exist?(yesterday_file)
    content = File.read(yesterday_file)
    verse_text = content.match(/<blockquote>(.*?)<\/blockquote>/m)[1]
    verse_ref = content.match(/<cite>(.*?)<\/cite>/)[1]
    return { text: verse_text, reference: verse_ref }
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

# --- Main Script Logic ---

# 1. Get Verse
verse = get_verse_of_the_day
unless verse
  puts "Fetching verse failed. Trying to use yesterday's verse."
  verse_data = get_previous_verse
  if verse_data
    verse = Votd::Verse.new(verse_data[:text], verse_data[:reference], 'ESV')
  else
    puts "Could not retrieve yesterday's verse. Exiting."
    exit 1
  end
end

puts "Verse for today: #{verse.reference} - #{verse.text}"

# 2. Generate Devotional
devotional_content = generate_devotional(verse.text, verse.reference)
unless devotional_content
  puts "Devotional generation failed. Using verse only."
  devotional_content = "<p>We apologize, but we couldn't generate the devotional content for today. Please reflect on the verse below.</p>"
end

# 3. Move previous today.html to archive
if File.exist?(TODAY_HTML_PATH)
  yesterday_date = (Date.today - 1).strftime('%Y-%m-%d')
  archive_path = File.join(ARCHIVE_DIR, "#{yesterday_date}.html")
  File.rename(TODAY_HTML_PATH, archive_path)
  puts "Archived yesterday's devotional to #{archive_path}"
end

# 4. Create new devotional HTML
today_date_formatted = Date.today.strftime('%B %d, %Y')
replacements = {
  'PAGE_TITLE' => "Devotional for #{today_date_formatted}",
  'DATE_FORMATTED' => today_date_formatted,
  'VERSE_REFERENCE' => verse.reference,
  'VERSE_TEXT' => verse.text,
  'DEVOTIONAL_CONTENT' => Kramdown::Document.new(devotional_content).to_html
}

# Generate dated file for the archive
dated_html_content = process_template(HTML_TEMPLATE_PATH, replacements)
dated_html_path = File.join(ARCHIVE_DIR, "#{Date.today.strftime('%Y-%m-%d')}.html")
File.write(dated_html_path, dated_html_content)
puts "Created dated devotional: #{dated_html_path}"

# Generate today.html (a copy of the dated one)
File.write(TODAY_HTML_PATH, dated_html_content)
puts "Created today.html"

# 5. Update index.html (simple version: just links to today.html)
# A more complex implementation could inject the content directly.

puts "Devotional generation complete."
