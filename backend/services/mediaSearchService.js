const axios = require('axios');

const UNSPLASH_API_KEY = process.env.UNSPLASH_API_KEY;
const PEXELS_API_KEY = process.env.PEXELS_API_KEY;
const PIXABAY_API_KEY = process.env.PIXABAY_API_KEY;

/**
 * Searches Unsplash for images.
 */
const searchUnsplash = async (query, page = 1, perPage = 15) => {
  if (!UNSPLASH_API_KEY) return [];
  try {
    const response = await axios.get(`https://api.unsplash.com/search/photos`, {
      params: { query, page, per_page: perPage },
      headers: { Authorization: `Client-ID ${UNSPLASH_API_KEY}` }
    });
    return response.data.results.map(item => ({
      source: 'unsplash',
      id: item.id,
      url: item.urls.regular,
      thumbnail: item.urls.thumb,
      type: 'image',
      author: item.user.name,
      authorUrl: item.user.links.html
    }));
  } catch (error) {
    console.error('Unsplash Search Error:', error.message);
    return [];
  }
};

/**
 * Searches Pexels for images and videos.
 */
const searchPexels = async (query, type = 'image', page = 1, perPage = 15) => {
  if (!PEXELS_API_KEY) return [];
  try {
    const endpoint = type === 'video' ? 'videos/search' : 'v1/search';
    const response = await axios.get(`https://api.pexels.com/${endpoint}`, {
      params: { query, page, per_page: perPage },
      headers: { Authorization: PEXELS_API_KEY }
    });
    
    if (type === 'video') {
      return response.data.videos.map(item => ({
        source: 'pexels',
        id: item.id.toString(),
        url: item.video_files[0]?.link,
        thumbnail: item.image,
        type: 'video',
        author: item.user.name,
        authorUrl: item.user.url
      }));
    } else {
      return response.data.photos.map(item => ({
        source: 'pexels',
        id: item.id.toString(),
        url: item.src.large,
        thumbnail: item.src.medium,
        type: 'image',
        author: item.photographer,
        authorUrl: item.photographer_url
      }));
    }
  } catch (error) {
    console.error('Pexels Search Error:', error.message);
    return [];
  }
};

/**
 * Searches Pixabay for images and videos.
 */
const searchPixabay = async (query, type = 'image', page = 1, perPage = 15) => {
  if (!PIXABAY_API_KEY) return [];
  try {
    const isVideo = type === 'video';
    const endpoint = isVideo ? 'videos/' : '';
    const response = await axios.get(`https://pixabay.com/api/${endpoint}`, {
      params: {
        key: PIXABAY_API_KEY,
        q: encodeURIComponent(query),
        page,
        per_page: perPage
      }
    });
    
    return response.data.hits.map(item => ({
      source: 'pixabay',
      id: item.id.toString(),
      url: isVideo ? item.videos.large.url : item.largeImageURL,
      thumbnail: isVideo ? item.picture_id : item.previewURL, 
      type: type,
      author: item.user,
      authorUrl: `https://pixabay.com/users/${item.user}-${item.user_id}/`
    }));
  } catch (error) {
    console.error('Pixabay Search Error:', error.message);
    return [];
  }
};

/**
 * Aggregates search results across multiple free stock media APIs.
 */
const aggregateMediaSearch = async (query, type = 'image', page = 1, perPage = 15) => {
  const perApi = Math.ceil(perPage / 3);
  
  const tasks = [];
  
  if (type === 'image' || type === 'all') {
    tasks.push(searchUnsplash(query, page, perApi));
  }
  tasks.push(searchPexels(query, type !== 'all' ? type : 'image', page, perApi));
  tasks.push(searchPixabay(query, type !== 'all' ? type : 'image', page, perApi));

  const results = await Promise.allSettled(tasks);
  
  const aggregated = results
    .filter(r => r.status === 'fulfilled')
    .map(r => r.value)
    .flat();
    
  return aggregated.sort(() => Math.random() - 0.5); // Shuffle results
};

module.exports = {
  aggregateMediaSearch,
  searchUnsplash,
  searchPexels,
  searchPixabay
};
