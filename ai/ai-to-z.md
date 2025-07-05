---
layout: "page"
title: "A(i) to Z"
description: "A starting point for learning about AI."
image: "/assets/ai-to-z/logo.png"
permalink: "/ai/ai-to-z.html"
order: 1
---

The goal of this page is not to dive into every detail of AI, but to provide a solid foundation and a starting point for anyone interested in learning about AI, whether you are a beginner or have some experience.

## Table of Contents

- [History](#history)
- [ML vs AI vs GenAI](#ml-vs-ai-vs-genai)
- [GenAI part 1](#genai-part-1)
  - [Introduction](#introduction)
  - [Vendors](#vendors)
  - [Models](#models)
  - [Providers](#providers)
  - [Prompts & messages](#prompts--messages)
  - [Tokens & Tokenization](#tokens--tokenization)
  - [Costs](#costs)
  - [Problems with models](#problems-with-models)
  - [Fine-tuning a model](#fine-tuning-a-model)
  - [Advanced concepts](#advanced-concepts)
- [GenAI part 2](#genai-part-2)
  - [Function calling](#function-calling)
  - [Model Context Protocol (MCP)](#model-context-protocol-mcp)
  - [Retrieval Augmented Generation (RAG)](#retrieval-augmented-generation-rag)
  - [Agents & Agentic AI](#agents--agentic-ai)
- [Usecases](#usecases)
  - [Chat interfaces](#chat-interfaces)
  - [Office 365](#office-365)
  - [Windows](#windows)
  - [GitHub](#github)
  - [Customer examples](#customer-examples)
- [Integrating AI into your applications](#integrating-ai-into-your-applications)
  - [Tools and IDEs](#tools-and-ides)
  - [Copilot](#copilot)
  - [Azure AI services](#azure-ai-services)
  - [Languages & SDKs](#languages--sdks)
  - [Semantic Kernel](#semantic-kernel)
- [(Near) future](#near-future)
- [Want to know more?](#want-to-know-more)

## History

Some fun history facts about AI, showing how long AI has been around and how it has evolved over time:

- 1956: The term "artificial intelligence" was coined at the Dartmouth Conference.
- 1966: ELIZA, an early natural language processing program, was created by Joseph Weizenbaum.
- 1997: IBM's Deep Blue defeated world chess champion Garry Kasparov.
- 2011: IBM's Watson won the quiz show Jeopardy! against human champions.
- 2012: The breakthrough in deep learning with AlexNet winning the ImageNet competition.
- 2014: The first Generative Adversarial Network (GAN) was introduced by Ian Goodfellow.
- 2018: OpenAI released the first version of GPT (Generative Pre-trained Transformer).
- 2020: OpenAI released GPT-3, a significant advancement in natural language processing.
- 2023: OpenAI released GPT-4, further enhancing capabilities in language understanding and generation.

## ML vs AI vs GenAI

- What is ML?
- What is AI and how is it different from ML?
- What is GenAI and how is it different from AI?

- What does HITL stand for and what does it mean in the context of AI? (Human In The Loop)
- Scaled GenAI: Techniques and strategies for scaling generative AI models and applications.

## GenAI part 1

### Introduction

- What is natural language processing (NLP)?
- What is a large language model (LLM)?
- What is a small language model (SLM)?
- Are there other types of models?

### Vendors

Many vendors, such as:

- OpenAI
- Google
- Anthropic
- Microsoft
- Hugging Face

Others? What are the differences between them? What does a vendor do (bridge to models and providers)?

### Models

What is a model?

There are many differences between models, like the following but more as well (described in the advanced section):

- Training date
- Cut-off
- Large or small
- Vendor
  
There are also many different models:

- ChatGPT 3.5, 4.0, 4.1, 4.5 (LLM)
- DeepSearch (LLM)
- Gemini 2.5 Flash & Pro (LLM)
- Claude Sonnet 4.0, Opus 4 (LLM)
- Grok (LLM)
- Phi (SLM)
- MAI (Future AI model from Microsoft, LLM? Should maybe be placed in the future section along with other future models?)
- DALL-E (Diffusion?)
- Stable Diffusion (Diffusion?)
- Midjourney (Diffusion?)
- Imagen (Diffusion?)
- Whisper (Speech recognition, what is this type of model called?)
- AIVA (Music generation, what is this type of model called?)
- GPT-4o & 4o mini (Multi modal? Large & small?)
- Smol (SLM?)

FAQ

- What is a GPT and why are not all models GPT?
- [GitHub Models](https://docs.github.com/en/github-models/about-github-models) is a suite of developer tools that take you from AI idea to ship, including a model catalog, prompt management, and quantitative evaluations. See providers section for more details.
- What does multi-modal mean and how can I use it?
- Why not train a model every month or week to keep it up-to-date? (link to training section in advanced?)

### Providers

What are they?

(Technical) components of a hosted model include:

- Proxy
- Load balancer
- Content filter
- What else?

Hosted solutions:

- OpenAI
- Google
- Microsoft
  - Azure OpenAI
  - GitHub Models
- Hugging Face  
- Many more

Self-hosting is possible too:

- Docker
- Olama
- Hugging Face

FAQ

- Do all hosted solutions use my data?
- Where is my data stored?
- Can I opt-out of data collection?
- How does the above change if I use an OpenAI model via Azure OpenAI?
- How does GitHub Models relate to GitHub Copilot?

### Prompts & messages

What are prompts and messages?

Different types of prompts and messages:

- User prompt
- System prompt
- Assistant message
  - Suggestions
  - Completions

Prompt engineering is the process of designing and optimizing prompts to improve the performance of AI models.

- Single shot prompts
- Few shot prompts
- Zero shot prompts
- Chain of thought prompts

Reusable prompts are prompts that can be reused across different interactions.

### Tokens & Tokenization

- What is a token?
- How does tokenization work?
- How many tokens are in a message?
- Why is this important?
- Can I switch between different tokenizers?
- Token limits and what happens when I exceed them? What to do?
- How does tokenization differ between models, for instance text vs images vs audio?

### Costs

- Context
- Chat history
- Prompts

### Problems with models

- Hallucinations
- Input-poisoning
- Jailbreaking
- Why can't I use a LLM to calculate? Or count?

### Fine-tuning a model

- Grounding
- Temperature
- Top P

### Advanced concepts

What is a neural network?

Training a model:

- Transformers
- Data
- Cut-off date
- Weights
- Parameters
- Context
- Input size
- Output size
- Seed
- Vocabulary
- Attention

A deepdive into the above can be seen here where [Andrej Karpathy builds ChatGPT from scratch](https://www.youtube.com/watch?v=kCc8FmEb1nY).

These 3 might belong in the basics?

- Vectors
- Embeddings
- Inference

## GenAI part 2

### Function calling

What is it?

``` text
Description: Vliegduur van A naar B
Definition:
  Params
    A: bla
    B: bla
Example:
```

How does the model match the function to the prompt?

### Model Context Protocol (MCP)

- What is it and what problem does it fix?
- Components
  - Host (for instance your IDE)
  - Client
  - Server
- How does it relate to OpenAI function calling?
- Security missing (OAuth support coming)
  - [OAuth support in draft](https://modelcontextprotocol.io/specification/draft/basic/authorization) with [Auth0 & Cloudflare to the rescue in the meantime](https://auth0.com/blog/secure-and-deploy-remote-mcp-servers-with-auth0-and-cloudflare/)
- Risks

- [MCP course](https://huggingface.co/learn/mcp-course/unit0/introduction)

### Retrieval Augmented Generation (RAG)

- What is it and why is it important?
- How does it differ from MCP and function calling?
- When to use or implement functions, when MCP and when RAG?

### Agents & Agentic AI

- What makes something an agent?
- Is there a formal definition or interface?
- What's the difference compared to a MCP server and what to place where?
- What does agentic mean?

## Usecases

### Chat interfaces

Explain the popular chat interfaces and what you can do with them.

### Office 365

What is the role of AI in Office 365?

### Windows

### GitHub

### Customer examples

Show examples of how customers are using AI in their applications.

## Integrating AI into your applications

### Tools and IDEs

- Visual Studio (Code)
- Rider
- Claude Desktop?
- GitHub Codespaces?
- Jupyter Notebooks?

### Copilot

- GitHub Copilot, Microsoft Copilot, Azure Copilot, etc.
- Ask vs Edit vs Agent in Copilot
- Copilot spaces
- Copilot coding agent (Padawan?)
- Copilot review agent

Lots of examples can be found in the [Xebia GitHub Copilot Updates](https://github-copilot.xebia.ms/).

FAQ

- When should I refactor using my IDE and when should I use a tool like Copilot?

### Azure AI services

What is Azure AI Foundry?

What is Azure OpenAI?

What other Azure services are there?

Do I need to use those "low-level" services directly anymore? Or can I skip ahead to the next section?

- Azure AI Agent Service: Combine generative AI models with tools that allow agents to access and interact with real-world data sources.
- Azure AI Foundry Models (previously Model Inference): Performs model inference for flagship models in the Azure AI model catalog.
- Azure AI Search: Bring AI-powered cloud search to your mobile and web apps.
- Bot Service: Create bots and connect them across multiple channels.
- Content Safety: Detects unwanted or harmful content.
- Custom Vision: Customize image recognition for your business needs.
- Document Intelligence: Turn documents into intelligent, data-driven solutions.
- Face: Detect and identify people and emotions in images.
- Immersive Reader: Help users read and comprehend text more easily.
- Language: Build apps with advanced natural language understanding capabilities.
- Speech: Speech to text, text to speech, translation, and speaker recognition.
- Translator: Use AI-powered translation technology to translate more than 100 languages and dialects.
- Video Indexer: Extract actionable insights from your videos.
- Vision: Analyze content in images and videos.

### Languages & SDKs

Most popular languages have an SDK for AI, such as:

- Python
- JavaScript
- Java
- C#

Many SDKs:

- Azure AI
- OpenAI
- Hugging Face
- MCP
- Smolagents: A library that enables you to run powerful agents in a few lines of code.
- LangChain: A framework for building applications powered by language models.
- LangGraph: A framework for building AI applications with a focus on graph-based workflows.
- [Semantic Kernel](#semantic-kernel): Very important in the .NET space, so has a separate section.
- Smart components: .NET Smart Components shows you how to add genuinely useful AI-powered features to your .NET apps quickly, easily, and without risking wasted effort.

Maybe show a matrix of currently popular languages and their SDKs?

### Semantic Kernel

- What is it?
- What components are there and which AI capability do they deliver?
  - Plugins/planners vs (OpenAI?) function calling vs MCP?

FAQ

- Adding Azure OpenAI vs OpenAI in C#, what are the differences?
- What is still missing?

## (Near) future

Lots of things are happening in the AI space, a few things to keep an eye on:

- A2A (Agent to Agent)
- ACP (Agent Communication Protocol) from [BeeAI](https://github.com/i-am-bee)

A good starting point is here: [What does MCP, A2A, and ACP mean?](https://akka.io/blog/mcp-a2a-acp-what-does-it-all-mean)

Also SLIM (Secure Low-Latency Interactive Messaging), previously called AGP (Agent Gateway Protocol) is interesting. Find more information here: [SLIM](https://github.com/agntcy/slim).

[llms.txt](https://llmstxt.org/) is another initative to keep an eye on, suggesting adding a markdown file to websites to provide LLM-friendly content. [Here is an example for GoFastMCP](https://gofastmcp.com/llms-full.txt).

Microsoft is also embracing MCP and adding support for a central server registry, server isolation and other security features. [Read the blogpost here](https://blogs.windows.com/windowsexperience/2025/05/19/securing-the-model-context-protocol-building-a-safer-agentic-future-on-windows).

## Want to know more?

Sell [Xebia Microsoft Services](https://xebia.com/digital-transformation/microsoft-services/) here with a bit less blabla than on the website? :)

[Hugging Face](https://huggingface.co/) is a great resource for learning about AI and finding models, datasets, and more.

[Rob Bos' LinkedIn Learning Course on AI development with GitHub models](http://www.linkedin.com/learning/enterprise-ai-development-with-github-models-and-azure)

[GitHub Skills](https://skills.github.com/) has a few courses on AI and related topics.

[Let's build GPT: from scratch, in code, spelled out](https://www.youtube.com/watch?v=kCc8FmEb1nY) by Andrej Karpathy.
