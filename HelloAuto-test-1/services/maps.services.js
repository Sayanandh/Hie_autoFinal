const axios = require('axios');

module.exports.getAddressLocation = async (address) => {
    const mapboxToken = process.env.MAPBOX_API_KEY; // Ensure you have your Mapbox API key in your .env file
    const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(address)}.json?access_token=${mapboxToken}`;

    try {
        const response = await axios.get(url);
        const data = response.data;

        if (data.features && data.features.length > 0) {
            const [lng, lat] = data.features[0].center; // Correct the naming to lat and lng
            return { lat, lng }; // Corrected to return lat, lng
        } else {
            throw new Error('No location found for the given address');
        }
    } catch (error) {
        console.error('Error fetching location:', error);
        throw new Error('Failed to fetch location');
    }
};

module.exports.getDistanceTime = async (origin, destination) => {
    const mapboxToken = process.env.MAPBOX_API_KEY; // Ensure the Mapbox API key is set in the .env file

    try {
        // Get coordinates for origin and destination
        const originCoordinates = await module.exports.getAddressLocation(origin);
        const destinationCoordinates = await module.exports.getAddressLocation(destination);

        // Construct the API URL with the coordinates
        const apiUrl = `https://api.mapbox.com/directions/v5/mapbox/driving/${originCoordinates.lng},${originCoordinates.lat};${destinationCoordinates.lng},${destinationCoordinates.lat}?access_token=${mapboxToken}`;
        console.log("this is api url", apiUrl);

        const response = await axios.get(apiUrl);
        console.log("this is response", response);
        const { routes } = response.data;

        if (routes && routes.length > 0) {
            const { distance, duration } = routes[0]; // Extract distance (meters) and duration (seconds)
            return { distance, duration };
        } else {
            throw new Error('No route found for the specified locations.');
        }
    } catch (error) {
        console.error('Error while fetching distance and time:', error.message);
        throw new Error('Unable to retrieve distance and time information.');
    }
};


module.exports.getAutoSuggestions = async (query) => {
    const mapboxToken = process.env.MAPBOX_API_KEY;

    if (!mapboxToken) {
        throw new Error("Mapbox API key is missing. Please set the MAPBOX_API_KEY environment variable.");
    }

    // Kerala's bounding box: [minLongitude, minLatitude, maxLongitude, maxLatitude]
    const keralaBbox = "&bbox=74.52,8.32,77.35,12.78"; // Covers Kerala

    // Function to fetch data from Mapbox with Kerala-specific parameters
    const fetchSuggestions = async () => {
        const url = `https://api.mapbox.com/geocoding/v5/mapbox.places/${encodeURIComponent(query)}.json?types=place,poi,locality,neighborhood&country=IN${keralaBbox}&access_token=${mapboxToken}`;
        
        try {
            const response = await axios.get(url);
            return response.data.features || [];
        } catch (error) {
            console.error('Error fetching suggestions:', error.response ? error.response.data : error.message);
            return [];
        }
    };

    // Fetch places and landmarks within Kerala
    const suggestions = await fetchSuggestions();

    if (suggestions.length > 0) {
        return suggestions.map(feature => ({
            name: feature.place_name,   // Full place name
            type: feature.place_type[0] // Type (e.g., 'poi', 'place', etc.)
        }));
    } else {
        throw new Error('No suggestions found for the given query in Kerala');
    }
};
