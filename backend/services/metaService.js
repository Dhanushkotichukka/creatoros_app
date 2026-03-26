const axios = require('axios');
require('dotenv').config();

const META_API_VERSION = 'v19.0';

exports.getInstagramProfile = async (accessToken) => {
    try {
        const response = await axios.get(`https://graph.facebook.com/${META_API_VERSION}/me?fields=id,name,accounts{instagram_business_account{id,username,profile_picture_url}}&access_token=${accessToken}`);
        return response.data;
    } catch (error) {
        console.error('Error fetching Instagram profile:', error.response?.data || error.message);
        throw error;
    }
};

exports.getInsights = async (instagramId, accessToken) => {
    try {
        const response = await axios.get(`https://graph.facebook.com/${META_API_VERSION}/${instagramId}/insights?metric=impressions,reach,profile_views&period=day&access_token=${accessToken}`);
        return response.data;
    } catch (error) {
        console.error('Error fetching Instagram insights:', error.response?.data || error.message);
        throw error;
    }
};
