---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: "home"
---

# GitHub Copilot Hub

Welcome to the Xebia GitHub Copilot Hub. Here you will find resources, articles, and tools related to GitHub Copilot. Like what you see and want to know more? Have a look at our [GitHub training program](https://academy.xebia.com/discipline/github/)! Want to know more about Microsoft AI in general? Check out our [Microsoft AI Hub](https://ai.xebia.ms) too!

<!-- Navigation Links Section -->
{%- assign default_paths = site.pages | sort: "order" | map: "path" -%}
{%- assign page_paths = site.header_pages | default: default_paths -%}
<div class="bottom-navigation">
  <div class="nav-grid">
    {%- for path in page_paths -%}
      {%- assign my_page = site.pages | where: "path", path | first -%}
      {%- if my_page.title -%}
      <a href="{{ my_page.url | relative_url }}" class="nav-square">
        <span class="nav-title">{{ my_page.title | escape }}</span>
        <span class="nav-desc">
          {%- if my_page.description -%}
            {{ my_page.description | escape }}
          {%- else -%}
            {{ my_page.title | escape }}
          {%- endif -%}
        </span>
      </a>
      {%- endif -%}
    {%- endfor -%}
  </div>
</div>
