# GitHub Copilot Updates Website

This repository contains a Jekyll-based website for GitHub Copilot updates, featuring blogs, news, and resources about GitHub Copilot and AI development.

## Repository Structure

```text
github-copilot-updates/
├── _config.yml                 # Jekyll configuration
├── _data/                      # Data files (JSON, YAML)
│   └── copilot_plans.json     # Copilot plans data
├── _includes/                  # Reusable template components
│   ├── data-tags-builder.html
│   ├── footer.html
│   ├── header.html
│   ├── social.html
│   ├── subnav.js
│   └── tag-filter.html
├── _layouts/                   # Page layouts
│   └── home.html
├── _sass/                      # Modular SCSS files
│   ├── _variables.scss         # Color and size variables
│   ├── _base.scss             # Global styles and typography
│   ├── _header.scss           # Header and navigation styles
│   ├── _footer.scss           # Footer styles
│   ├── _navigation.scss       # Navigation grid and squares
│   ├── _homepage.scss         # Homepage-specific styles
│   ├── _posts.scss            # Post grid and styling
│   ├── _filters.scss          # Tag filter button styles
│   └── _subnav.scss           # Subnavigation styles
├── assets/                     # Static assets
│   ├── main.scss              # Main SCSS import file
│   ├── *.svg                  # SVG icons and logos
│   └── *.jpg, *.png           # Images
├── _posts/                     # Blog posts (Markdown)
├── _news/                      # News articles (Markdown)
├── _videos/                    # Video content (Markdown)
├── ai/                         # AI-related pages
├── github-copilot/            # GitHub Copilot specific pages
└── _site/                      # Generated site (ignored in git)
```

## CSS Architecture

The styles have been modularized for better maintainability:

- **`_variables.scss`**: All color variables and constants
- **`_base.scss`**: Global styles, typography, and base elements
- **`_header.scss`**: Header navigation and contact button
- **`_footer.scss`**: Footer styling and RSS link
- **`_navigation.scss`**: Navigation grids and squares
- **`_homepage.scss`**: Homepage-specific navigation with background images
- **`_posts.scss`**: Post grid layout and cards
- **`_filters.scss`**: Tag filtering buttons and controls
- **`_subnav.scss`**: Subpage navigation styling

The main `assets/main.scss` file imports all modules in the correct order.

## Development Setup

### Prerequisites

- Docker (for dev container support)
- VS Code with Dev Containers extension

### Getting Started

1. **Clone the repository**:

   ```bash
   git clone <repository-url>
   cd github-copilot-updates
   ```

2. **Open in Dev Container**:
   - Open the folder in VS Code
   - When prompted, click "Reopen in Container"
   - Or use Command Palette: `Dev Containers: Reopen in Container`

3. **Start the development server**:

   ```bash
   jekyll clean && bundle exec jekyll serve --force_polling --livereload
   ```

4. **Access the website**:
   - Open your browser to `http://localhost:4000`
   - The site will automatically reload when you make changes to files

### Development Commands

- **Clean build**: `jekyll clean` - Removes the `_site` directory
- **Build site**: `bundle exec jekyll build` - Generates the static site
- **Serve with live reload**: `bundle exec jekyll serve --force_polling --livereload`
- **Serve with drafts**: `bundle exec jekyll serve --drafts --force_polling --livereload`

### Dev Container Features

The dev container includes:

- Ruby with Jekyll and Bundler
- Node.js with npm and ESLint
- Git and common development tools
- All necessary dependencies pre-installed

## Content Management

### Adding New Posts

Create new Markdown files in the `_posts/` directory with the naming convention:

```text
YYYY-MM-DD-title-of-post.md
```

### Adding News Items

Create new Markdown files in the `_news/` directory following the same date convention.

### Updating Styles

Modify the appropriate SCSS file in the `_sass/` directory:

- Global changes → `_base.scss`
- Header changes → `_header.scss`
- Homepage changes → `_homepage.scss`
- etc.

Changes will be automatically compiled and live-reloaded in the browser.

## Contributing

1. Make your changes in the appropriate files
2. Test locally using the development server
3. Ensure the site builds without errors: `bundle exec jekyll build`
4. Submit a pull request with your changes

## Live Reload

The `--livereload` flag enables automatic browser refresh when files change. The `--force_polling` flag ensures file watching works properly in Docker containers and various development environments.
