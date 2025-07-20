# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby-based daily devotional generator that automates content creation using the Claude Sonnet 4 API and deploys to GitHub Pages. The system fetches daily Bible verses via the `votd` gem and generates devotional content automatically through GitHub Actions.

## Development Commands

### Ruby Environment
- `bundle install` - Install Ruby dependencies
- `bundle exec ruby scripts/generate_devotional.rb` - Run devotional generation script manually
- `ruby -v` - Check Ruby version (requires 3.4.1)

### Git and Deployment
- GitHub Actions workflow runs automatically at 9:00 AM UTC daily
- Manual trigger: Use GitHub's "Run workflow" button on Actions tab
- Deployment is automatic to GitHub Pages upon successful workflow completion

## Architecture

### Core Components

**Scripts (`scripts/generate_devotional.rb`)**
- Main generation script that orchestrates the entire process
- Fetches verse using `votd` gem (ESV Bible Gateway)
- Calls Claude Sonnet 4 API for devotional content generation
- Processes HTML templates with verse and generated content
- Archives previous day's content and creates new files

**Templates Directory**
- `devotional_prompt.txt` - Contains the detailed prompt for Claude API including theological guidelines, format requirements, and style guidelines
- `devotional_template.html` - HTML template with placeholders for generated content

**Content Management**
- `today.html` - Always contains the current day's devotional
- `devotionals/` - Archive directory with dated HTML files (YYYY-MM-DD.html)
- `index.html` - Landing page that displays current devotional

**GitHub Actions Workflow (`.github/workflows/daily-devotional.yml`)**
- Automated daily execution using cron schedule
- Ruby environment setup and dependency installation
- Devotional generation and automatic git commit/push
- GitHub Pages deployment

### Data Flow

1. **Verse Retrieval**: Script fetches ESV verse using `votd` gem
2. **Content Generation**: Verse is sent to Claude API with detailed prompt template
3. **Template Processing**: Generated content is injected into HTML template with placeholders
4. **File Management**: Previous `today.html` is archived with date, new content becomes current
5. **Deployment**: Changes are committed and deployed to GitHub Pages

### Key Configuration

**Environment Variables**
- `ANTHROPIC_API_KEY` - Required secret for Claude API access

**API Configuration**
- Model: `claude-sonnet-4-20250514`
- Max tokens: 1500
- API URL: `https://api.anthropic.com/v1/messages`

**Template Placeholders**
- `{{PAGE_TITLE}}` - HTML page title
- `{{DATE_FORMATTED}}` - Human-readable date
- `{{VERSE_REFERENCE}}` - Bible reference (e.g., "John 3:16")
- `{{VERSE_TEXT}}` - Full verse text
- `{{DEVOTIONAL_CONTENT}}` - AI-generated devotional (processed through Kramdown)

### Error Handling

The script includes fallbacks:
- If verse fetch fails, attempts to use previous day's verse from archive
- If Claude API fails, uses placeholder content with verse only
- Comprehensive error logging for debugging

### Theological Framework

Content generation follows Reformed theological principles with specific guidelines for:
- Scripture authority and Christ-centered exposition
- Salvation by grace through faith
- Practical sanctification and Christian living
- Confessional tie-ins (Westminster, Heidelberg, Belgic Confession)
- Balance of doctrinal depth with accessibility