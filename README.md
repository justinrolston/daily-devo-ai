# Daily Devotional Generator

This project automates the generation and publication of a daily devotional website using the `votd` Ruby gem, Claude Sonnet 4, and GitHub Actions.

## Features

- **Automated Content:** Fetches the Verse of the Day (ESV) and generates a unique devotional using AI.
- **Daily Updates:** Runs automatically every day at 4 AM EST.
- **GitHub Pages:** Publishes the website for free using GitHub Pages.
- **Archiving:** Keeps a complete archive of all past devotionals.
- **Customizable:** Easily modify the prompt, layout, and styles.
- **Analytics Tracking:** Google Analytics 4 integration for visitor tracking and insights.

## How It Works

1.  **Verse of the Day:** A GitHub Actions workflow runs a Ruby script daily. The script uses the `votd` gem to fetch the Verse of the Day from the Bible (ESV version).
2.  **AI Devotional:** The verse is sent to the Claude Sonnet 4 API along with a customizable prompt to generate a devotional reflection.
3.  **HTML Generation:** The script takes the verse and the AI-generated content and injects them into a pre-defined HTML template.
4.  **File Updates:**
    *   The previous day's `today.html` is moved to the `devotionals/` archive with a dated filename (`YYYY-MM-DD.html`).
    *   A new `today.html` is created with the latest devotional.
    *   The `index.html` landing page is updated to display the new devotional and link to the archive.
5.  **Deployment:** The workflow commits the new and updated files to the repository and deploys them to GitHub Pages.

## Project Structure

```
.
├── .github/workflows/  # GitHub Actions workflow
├── assets/             # CSS and JavaScript
├── devotionals/        # Archive of daily devotionals
├── scripts/            # Ruby generation script
├── templates/          # HTML and prompt templates
├── Gemfile             # Ruby dependencies
├── _config.yml         # GitHub Pages configuration
├── index.html          # Main landing page
└── today.html          # Always shows the latest devotional
```

## Customization

You can easily customize the devotional's content, appearance, and structure.

### 1. Devotional Prompt

To change the instructions for the AI, edit `templates/devotional_prompt.txt`. You can modify the tone, length, or focus of the generated content.

**Available Placeholders:**

*   `{{VERSE_REFERENCE}}`: The Bible reference for the verse (e.g., "John 3:16").
*   `{{VERSE_TEXT}}`: The full text of the verse.

### 2. HTML Layout

To change the structure of the devotional pages, edit `templates/devotional_template.html`.

**Available Placeholders:**

*   `{{PAGE_TITLE}}`: The title of the HTML page.
*   `{{DATE_FORMATTED}}`: The formatted date of the devotional.
*   `{{VERSE_REFERENCE}}`: The Bible reference.
*   `{{VERSE_TEXT}}`: The verse text.
*   `{{DEVOTIONAL_CONTENT}}`: The AI-generated devotional content.

### 3. Styling

To change the website's appearance, edit `assets/css/style.css`. This file controls all colors, fonts, and layout.

## Setup

1.  **Clone the repository.**
2.  **Configure the `votd` gem** in `scripts/generate_devotional.rb` if you need a different Bible version (currently set to ESV).
3.  **Add your Anthropic API key** as a secret in your GitHub repository with the name `ANTHROPIC_API_KEY`.
4.  **Enable GitHub Pages** in your repository settings, configured to deploy from the `main` branch and the `/ (root)` directory.
5.  **Set up Google Analytics** (optional but recommended):
    *   Create a Google Analytics 4 property at https://analytics.google.com
    *   Get your Measurement ID (format: `G-XXXXXXXXXX`)
    *   Replace `G-DBST2YM1G8` in `templates/devotional_template.html` and `index.html` with your tracking ID

## Analytics

The site includes Google Analytics 4 tracking (Measurement ID: `G-DBST2YM1G8`) to monitor visitor engagement and content performance.

**Analytics Dashboard:** https://analytics.google.com/analytics/web/#/p497543804/realtime/overview?params=_u..nav%3Dmaui

**What's Tracked:**
- Page views for each devotional
- Unique visitor counts
- Geographic distribution of readers
- Device types (mobile/desktop)
- Traffic sources and referrals
- Popular devotional content

## Troubleshooting

-   **Action Not Running:** Check the cron schedule in `.github/workflows/daily-devotional.yml` and ensure it's correct for your timezone.
-   **API Errors:** Ensure your `ANTHROPIC_API_KEY` is correct and has sufficient credits. Check the Actions logs for error messages from the Claude API.
-   **File Not Found:** Verify that all template and script paths are correct.
-   **Analytics Not Working:** Verify the Google Analytics Measurement ID is correctly set in both HTML template files.

## Contributing

Contributions are welcome! Please feel free to submit a pull request with any improvements or bug fixes.

1.  Fork the repository.
2.  Create a new branch (`git checkout -b feature/your-feature`).
3.  Make your changes.
4.  Commit your changes (`git commit -am 'Add new feature'`).
5.  Push to the branch (`git push origin feature/your-feature`).
6.  Create a new Pull Request.
