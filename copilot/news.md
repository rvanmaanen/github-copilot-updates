---
layout: "page"
title: "News"
description: "Latest updates and articles related to GitHub Copilot."
excerpt_separator: <!--excerpt_end-->
order: 1
---

{%- assign date_format = "%Y-%m-%d" -%}

    <ul class="post-list">
        {%- for post in site.news -%}
        <li>
        <a href="{{ post.url | relative_url }}">
            {{ post.date | date: date_format }} - {{ post.title | escape }}
        </a>
        {%- if site.show_excerpts -%}
        {{ post.excerpt }}
        {%- endif -%}
        </li>
        {%- endfor -%}
    </ul>

