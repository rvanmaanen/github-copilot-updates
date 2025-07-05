---
layout: "post"
title: "GitHub Models and Inference API"
description: "Tonight, I had the idea of starting a new project to test and demo new area’s and features of ASP.NE..."
author: "Rob Bos"
excerpt_separator: <!--excerpt_end-->
canonical_url: "https://devopsjournal.io/blog/2024/09/29/GitHub-Models-API"
tags: "[]"
categories: "[AI]"
feed_name: "Rob Bos"
feed_url: "https://devopsjournal.io/blog/atom.xml"
---

Need to use the Azure Inference AI SDK in Python against Azure OpenAI? Then this tip is for you! I ran into an issue converting the default examples to not run against GitHub’s Model endpoint but against an Azure OpenAI endpoint. The code example below says it all: configure your credential the correct way to get this to work. import os from azure.ai.inference import ChatCompletionsClient from azure.ai.inference.models import SystemMessage, UserMessage from azure.core.credentials import AzureKeyCredential # Set the runtime to "GITHUB" if you are running this code in GitHub # or something else to hit your own Azure OpenAI endpoint runtime="AZURE" client = None if runtime=="GITHUB": print("Running in GitHub") token = os.environ["GITHUB_TOKEN"] ENDPOINT = "https://models.inference.ai.azure.com" client = ChatCompletionsClient( endpoint=ENDPOINT, credential=AzureKeyCredential(token), ) else: print("Running in Azure") token = os.environ["AI_TOKEN"] ENDPOINT = "https://xms-openai.openai.azure.com/openai/deployments/gpt-4o" client = ChatCompletionsClient( endpoint=ENDPOINT, credential=AzureKeyCredential(""), # Pass in an empty value here! headers={"api-key": token}, # Include your token here #api_version="2024-06-01" # AOAI api-version is not required ) 

This post appeared first on The Rob Bos. [Read the entire article here](https://devopsjournal.io/blog/2024/09/29/GitHub-Models-API)
