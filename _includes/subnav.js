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
      if ((entry === 'ai' && link.href.includes('/ai')) || 
          (entry === 'github-copilot' && link.href.includes('/github-copilot'))) {
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
      
      // Direct URL match
      if (currentPath === linkPath) {
        isActive = true;
      }
      // Check if we're on a news page and this is the news link
      else if (currentPath.startsWith('/news/') && linkPath.includes('/news.html')) {
        isActive = true;
      }
      // Check if we're on a blog page and this is the blog link
      else if (currentPath.startsWith('/blogs/') && linkPath.includes('/blogs.html')) {
        isActive = true;
      }
      // Check if we're on a video page and this is the video link
      else if (currentPath.startsWith('/videos/') && linkPath.includes('/videos.html')) {
        isActive = true;
      }
      // Check if current path contains the link path (for subsections)
      else if (linkPath !== '' && currentPath.indexOf(linkPath.replace('.html', '')) === 0) {
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
