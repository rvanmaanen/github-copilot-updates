---
# Feel free to add content and custom Front Matter to this file.
# To modify the layout, see https://jekyllrb.com/docs/themes/#overriding-theme-defaults
layout: "home"
permalink: "/ai.html"
---

# Microsoft AI Hub

<!-- Navigation Links Section -->
{%- assign default_paths = site.pages | sort: "order" | map: "path" -%}
{%- assign page_paths = site.header_pages | default: default_paths -%}
{%- assign ai_page_paths = page_paths | where_exp: "path", "path contains 'ai/'" -%}

<div class="bottom-navigation">
  <div class="nav-grid">
    {%- for path in ai_page_paths -%}
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
