/* Navigation data for dynamic subnav */
window.navData = {
  'ai': [
    {% for page in site.pages -%}
    {%- if page.url contains '/ai/' and page.title -%}
    { title: {{ page.title | jsonify }}, url: {{ page.url | relative_url | jsonify }}, order: {{ page.order | default: 999 }} },
    {%- endif -%}
    {%- endfor -%}
  ],
  'github-copilot': [
    {% for page in site.pages -%}
    {%- if page.url contains '/github-copilot/' and page.title -%}
    { title: {{ page.title | jsonify }}, url: {{ page.url | relative_url | jsonify }}, order: {{ page.order | default: 999 }} },
    {%- endif -%}
    {%- endfor -%}
  ]
};

/* Dynamic subnav handler */
(function() {
  // Check if subnav is already shown (from server-side detection)
  var existingSubnav = document.querySelector('.subnav-wrapper');
  if (existingSubnav) {
    return; // Already handled server-side
  }
  
  // Parse query parameters
  var urlParams = new URLSearchParams(window.location.search);
  var entry = urlParams.get('entry');
  
  if (entry === 'ai' || entry === 'github-copilot') {
    // Add active class to main navigation
    var mainNavLinks = document.querySelectorAll('.site-nav .page-link');
    mainNavLinks.forEach(function(link) {
      link.classList.remove('active');
      var linkHref = link.getAttribute('href');
      if ((entry === 'ai' && linkHref.includes('/ai')) || 
          (entry === 'github-copilot' && linkHref.includes('/github-copilot'))) {
        link.classList.add('active');
      }
    });
    
    // Create the subnav dynamically
    var header = document.querySelector('.site-header');
    var subnavWrapper = document.createElement('div');
    subnavWrapper.className = 'subnav-wrapper';
    
    var subnav = document.createElement('nav');
    subnav.className = 'site-subnav';
    
    // Get the links for the current section
    var sectionLinks = window.navData[entry] || [];
    
    // Sort links by order property
    sectionLinks.sort(function(a, b) {
      return (a.order || 999) - (b.order || 999);
    });
    
    // Create the navigation links
    sectionLinks.forEach(function(link) {
      var a = document.createElement('a');
      a.className = 'subpage-link';
      a.href = link.url;
      a.textContent = link.title;
      
      // Check if this is the active page
      var currentPath = window.location.pathname;
      var linkPath = link.url;
      var isActive = false;
      
      // Detect base path dynamically by looking at script tag or link hrefs
      var basePath = '';
      var scriptSrc = document.querySelector('script[src*="/assets/"]');
      if (scriptSrc) {
        var src = scriptSrc.getAttribute('src');
        var assetsIndex = src.indexOf('/assets/');
        if (assetsIndex > 0) {
          basePath = src.substring(0, assetsIndex);
        }
      }
      
      // If no base path detected from assets, try to detect from current path structure
      if (!basePath && currentPath.includes('/github-copilot-updates/')) {
        basePath = '/github-copilot-updates';
      }
      
      // Extract the relative path from the current URL (removing base path if present)
      var relativePath = basePath && currentPath.indexOf(basePath) === 0 ? currentPath.replace(basePath, '') : currentPath;
      
      // Ensure linkPath is relative (remove base path if present)
      if (basePath && linkPath.indexOf(basePath) === 0) {
        linkPath = linkPath.replace(basePath, '');
      }
      
      // Direct URL match
      if (relativePath === linkPath) {
        isActive = true;
      }
      // Check if we're on a news page and this is the news link
      else if (relativePath.startsWith('/news/') && linkPath.includes('/news.html')) {
        isActive = true;
      }
      // Check if we're on a blog page and this is the blog link
      else if (relativePath.startsWith('/blogs/') && linkPath.includes('/blogs.html')) {
        isActive = true;
      }
      // Check if we're on a video page and this is the video link
      else if (relativePath.startsWith('/videos/') && linkPath.includes('/videos.html')) {
        isActive = true;
      }
      // Check if current path contains the link path (for subsections)
      else if (linkPath !== '' && relativePath.indexOf(linkPath.replace('.html', '')) === 0) {
        isActive = true;
      }
      
      if (isActive) {
        a.className += ' active';
      }
      
      subnav.appendChild(a);
    });
    
    // Only add subnav if we have links
    if (sectionLinks.length > 0) {
      subnavWrapper.appendChild(subnav);
      header.insertAdjacentElement('afterend', subnavWrapper);
    }
  }
})();
