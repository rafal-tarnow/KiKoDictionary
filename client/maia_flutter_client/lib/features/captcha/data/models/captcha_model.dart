class CaptchaModel {
  final String id; // UUID
  final String image; // Base64 string

  CaptchaModel({required this.id, required this.image});

  factory CaptchaModel.fromJson(Map<String, dynamic> json) {
    return CaptchaModel(
      id: json['id'] as String,
      image: json['image'] as String,
    );
  }
}

class CaptchaVerifyRequest {
  final String id;
  final String answer;

  CaptchaVerifyRequest({required this.id, required this.answer});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer': answer,
    };
  }
}

class CaptchaVerifyResponse {
  final bool isValid;

  CaptchaVerifyResponse({required this.isValid});

  factory CaptchaVerifyResponse.fromJson(Map<String, dynamic> json) {
    return CaptchaVerifyResponse(
      isValid: json['is_valid'] as bool,
    );
  }
}