class CreateProductReviewRequestDTO {
  final String? reviewerName; // Optional: server uses authenticated user's name or "Anonymous"
  final int? rating;         // Optional for anonymous, mandatory for logged-in (1-5)
  final String? comment;      // Optional, but server enforces (rating or comment must exist)

  CreateProductReviewRequestDTO({
    this.reviewerName,
    this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    // Only include fields if they have a value, matching server-side expectations
    if (reviewerName != null) { // Changed condition to allow empty string if not null
      data['reviewerName'] = reviewerName;
    }
    if (rating != null) {
      data['rating'] = rating;
    }
    // Send comment if it's not null and not empty, or if it's null (to explicitly clear it if API supports)
    // Based on server logic, empty comment is fine if rating is present.
    // If comment is the only thing, it must not be empty.
    if (comment != null) { 
      data['comment'] = comment;
    }
    return data;
  }
}
