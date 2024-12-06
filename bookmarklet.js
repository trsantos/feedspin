javascript:location.href='https://feedspin.net/feeds/new?feed='+document.location.href;

javascript: (() => {
  const selectors = [
    'link[rel="alternate"][type="application/atom+xml"]',
    'link[rel="alternate"][type="application/rss+xml"]',
    'link[rel="alternate"][type="application/xml"]',
    'link[rel="alternate"][type="text/xml"]'
  ];
  let feedLink = document.querySelector(selectors.join(', '))?.href;

  feedLink ||= document.location.href;

  location.href = 'https://feedspin.net/feeds/new?feed=' + feedLink;
})();

javascript: (() => {
  const selectors = [
    'link[rel="alternate"][type="application/atom+xml"]',
    'link[rel="alternate"][type="application/rss+xml"]',
    'link[rel="alternate"][type="application/xml"]',
    'link[rel="alternate"][type="text/xml"]'
  ];
  let feedLink = document.querySelector(selectors.join(', '))?.href;

  const rootNodeName = document.getRootNode().documentElement.nodeName;
  if (!feedLink && ['rss', 'channel', 'feed'].includes(rootNodeName))
    feedLink = document.location.href;

  if (feedLink)
    location.href = 'https://feedspin.net/feeds/new?feed=' + feedLink;
  else
    alert('Could not find a feed link.')
})();
