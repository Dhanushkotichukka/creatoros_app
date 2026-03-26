const axios = require('axios');
require('dotenv').config();

exports.getLinkedInProfile = async (accessToken) => {
    try {
        const response = await axios.get('https://api.linkedin.com/v2/userinfo', {
            headers: { 'Authorization': `Bearer ${accessToken}` }
        });
        return response.data;
    } catch (error) {
        console.error('Error fetching LinkedIn profile:', error.response?.data || error.message);
        throw error;
    }
};

exports.publishShare = async (authorId, accessToken, text) => {
    try {
        const response = await axios.post('https://api.linkedin.com/v2/ugcPosts', {
            author: `urn:li:person:${authorId}`,
            lifecycleState: 'PUBLISHED',
            specificContent: {
                'com.linkedin.ugc.ShareContent': {
                    shareCommentary: { text: text },
                    shareMediaCategory: 'NONE'
                }
            },
            visibility: { 'com.linkedin.ugc.MemberNetworkVisibility': 'PUBLIC' }
        }, {
            headers: { 'Authorization': `Bearer ${accessToken}` }
        });
        return response.data;
    } catch (error) {
        console.error('Error publishing to LinkedIn:', error.response?.data || error.message);
        throw error;
    }
};
