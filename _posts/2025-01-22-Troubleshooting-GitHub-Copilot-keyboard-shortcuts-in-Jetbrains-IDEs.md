---
layout: "post"
title: "Troubleshooting GitHub Copilot keyboard shortcuts in Jetbrains IDEs"
description: "Azure CLI is widely used in GitHub Actions and Azure Pipelines, as well as many other CI/CD tools. O..."
author: "Jesse Houwing"
excerpt_separator: <!--excerpt_end-->
canonical_url: "https://jessehouwing.net/troubleshooting-github-copilot-keyboard-shortcuts-in-jetbrains-ides/"
tags: [GitHub,github copilot,jetbrains,rider]
categories: [Copilot,AI]
feed_name: "Jesse Houwing"
feed_url: "https://jessehouwing.net/rss/"
date: 2025-01-22T19:39:29Z
---

Jesse Houwing explains that many developers, including himself, have faced issues with GitHub Copilot keyboard shortcuts in Jetbrains IDEs like IntelliJ, Rider, and PyCharm. <!--excerpt_end--> The two main problems are: (1) Copilot’s default shortcuts often conflict with existing keymaps (such as Visual Studio 2022), requiring users to manually resolve conflicts by reassigning or removing other actions; and (2) conflicts between Copilot and Jetbrains’ own “Full line completion” plugin, especially when using remote IDEs. Jesse recommends ensuring both plugins are up to date and, if `tab` completion fails, disabling the Full line completion plugin both locally and remotely. This helps Copilot’s shortcuts work as intended.

This post appeared first on The Jesse Houwing. [Read the entire article here](https://jessehouwing.net/troubleshooting-github-copilot-keyboard-shortcuts-in-jetbrains-ides/)
