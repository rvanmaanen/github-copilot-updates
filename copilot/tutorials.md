---
layout: "page"
title: "Tutorials"
description: "A collection of tutorials to help you get started with GitHub Copilot."
excerpt_separator: <!--excerpt_end-->
order: 2
---

{%- assign date_format = "%Y-%m-%d" -%}

    <ul class="post-list">
        {%- for post in site.posts -%}
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