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

<style>
.bottom-navigation {
  padding-bottom: 10px;
}

.nav-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
  max-width: 1200px;
  margin: 0 auto;
}

.nav-square {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  min-height: 180px;
  padding: 30px 20px;
  background: rgba(246, 248, 250, 0.2);
  border: 2px solid rgba(3, 102, 214, 0.2);
  border-radius: 12px;
  text-decoration: none;
  color: inherit;
  transition: all 0.3s ease;
  text-align: center;
}

.nav-square:hover {
  transform: scale(1.05);
  background: rgba(246, 248, 250, 0.3);
  border-color: rgba(3, 102, 214, 0.4);
  box-shadow: 0 8px 25px rgba(0, 0, 0, 0.1);
  text-decoration: none;
  color: inherit;
}

.nav-title {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 8px;
}

.nav-desc {
  font-size: 14px;
  line-height: 1.4;
}

/* Responsive adjustments */
@media (max-width: 768px) {
  .nav-grid {
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 15px;
  }
  
  .nav-square {
    min-height: 140px;
    padding: 20px 15px;
  }
  
  .nav-title {
    font-size: 16px;
  }
  
  .nav-desc {
    font-size: 13px;
  }
}

@media (max-width: 480px) {
  .nav-grid {
    grid-template-columns: 1fr;
  }
}
</style>

