---
layout: "page"
title: "Videos"
description: "A collection of videos to help you get the most out of Microsoft AI technologies."
excerpt_separator: <!--excerpt_end-->
order: 4
permalink: "/ai/videos.html"
---

{%- assign date_format = "%Y-%m-%d" -%}

{%- assign posts = site.videos | where: "categories", "AI" | sort: 'date' | reverse  -%}
{% include tag-filter.html %}

<ul class="post-list">
  {%- for post in posts -%}
    {% include data-tags-builder.html %}

    <li class="post-item" data-tags="{{ all_tags }}" data-date="{{ post_date_iso }}">
      <a href="{{ post.url | relative_url }}?entry=ai">
        {{ post.date | date: date_format }} - {{ post.title | escape }}
      </a>
      {%- if site.show_excerpts -%}
        {{ post.excerpt }}
      {%- endif -%}
    </li>
  {%- endfor -%}
</ul>
