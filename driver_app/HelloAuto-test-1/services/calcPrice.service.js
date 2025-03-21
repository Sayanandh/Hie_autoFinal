function calculatePrice(distanceKm) {
    const ratePerKm = process.envIDE_CHARGE;
    const minimumCharge = process.env.MINIMUM_CHARGE;

    // If distance is less than 1 km, return the minimum charge
    if (distanceKm < 1) {
        return minimumCharge;
    }

    // Calculate charge and round up to the nearest integer
    const totalCharge = distanceKm * ratePerKm;
    return Math.ceil(totalCharge);
}

module.exports = calculatePrice;