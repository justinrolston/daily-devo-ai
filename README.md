# Daily Devotional Generator

Automates the generation and publication of a daily devotional website using the `votd` Ruby gem, Claude Sonnet 4, and GitHub Actions.

## How It Works

1. A GitHub Actions workflow runs daily at 9 AM UTC
2. The `votd` gem fetches the Verse of the Day (ESV)
3. The verse is sent to the Claude Sonnet 4 API with a theological prompt to generate a devotional reflection
4. The generated content is injected into an HTML template
5. The previous `today.html` is archived to `devotionals/YYYY-MM-DD.html`
6. Changes are committed and deployed to GitHub Pages

## Project Structure

```
.
├── .github/workflows/    # GitHub Actions workflow
├── assets/               # CSS and JavaScript
├── devotionals/          # Archive of past devotionals
├── scripts/              # Ruby generation script
├── templates/            # HTML and prompt templates
├── Gemfile               # Ruby dependencies
├── _config.yml           # GitHub Pages configuration
├── index.html            # Landing page
└── today.html            # Current day's devotional
```

## Setup

1. Clone the repository
2. Add your Anthropic API key as a repository secret named `ANTHROPIC_API_KEY`
3. Enable GitHub Pages in repository settings (deploy from `main` branch, `/ (root)` directory)
4. The workflow will run automatically — or trigger it manually from the Actions tab

## Local Development

```bash
bundle install
bundle exec ruby scripts/generate_devotional.rb
```

Requires Ruby 3.4.1.

## Customization

### Devotional Prompt

Edit `templates/devotional_prompt.txt` to change the tone, focus, or theological emphasis of generated content.

Available placeholders: `{{VERSE_REFERENCE}}`, `{{VERSE_TEXT}}`

### HTML Layout

Edit `templates/devotional_template.html` to change the page structure.

Available placeholders: `{{PAGE_TITLE}}`, `{{DATE_FORMATTED}}`, `{{VERSE_REFERENCE}}`, `{{VERSE_TEXT}}`, `{{DEVOTIONAL_CONTENT}}`

### Styling

Edit `assets/css/style.css` for visual changes.

## Theological Framework

Content is generated following Reformed theological principles, including Scripture authority, Christ-centered exposition, and references to the Westminster, Heidelberg, and Belgic Confessions.

## Troubleshooting

- **Workflow not running:** Check the cron schedule in `.github/workflows/daily-devotional.yml`
- **API errors:** Verify `ANTHROPIC_API_KEY` is set correctly and has sufficient credits
- **Blank content:** Check Actions logs — the script falls back to verse-only content if the API fails
