import os
import hmac
import hashlib
import razorpay
from typing import Dict, Any

class PaymentService:
    def __init__(self):
        self.key_id = os.getenv("RAZORPAY_KEY_ID", "rzp_test_placeholder")
        self.key_secret = os.getenv("RAZORPAY_KEY_SECRET", "secret_placeholder")
        self.webhook_secret = os.getenv("RAZORPAY_WEBHOOK_SECRET", "webhook_secret_placeholder")
        self.plan_id = os.getenv("RAZORPAY_PLAN_ID", "plan_placeholder")
        
        if self.key_id and self.key_secret and self.key_id != "rzp_test_placeholder":
            self.client = razorpay.Client(auth=(self.key_id, self.key_secret))
        else:
            print("PaymentService Warning: Razorpay credentials not set. Using mock mode.")
            self.client = None

    def create_subscription(self, user_id: str) -> Dict[str, Any]:
        print(f"[PaymentService] Creating subscription for user={user_id}, plan={self.plan_id}")
        if not self.client:
            return {
                "id": f"sub_mock_{user_id}",
                "entity": "subscription",
                "plan_id": self.plan_id,
                "status": "created",
                "short_url": "mock_url"
            }
        
        try:
            data = {
                "plan_id": self.plan_id,
                "total_count": 12, # E.g., 12 billing cycles (1 year)
                "quantity": 1,
                "customer_notify": 1,
                "notes": {
                    "user_id": user_id
                }
            }
            subscription = self.client.subscription.create(data=data)
            print(f"[PaymentService] Subscription created successfully: {subscription.get('id')}")
            return subscription
        except Exception as e:
            print(f"[PaymentService] Failed to create subscription: {str(e)}")
            raise e

    def verify_subscription(self, subscription_id: str, payment_id: str, signature: str) -> bool:
        print(f"[PaymentService] Verifying subscription: sub_id={subscription_id}, payment_id={payment_id}")
        if not self.client:
             return True

        try:
            params_dict = {
                'razorpay_subscription_id': subscription_id,
                'razorpay_payment_id': payment_id,
                'razorpay_signature': signature
            }
            self.client.utility.verify_subscription_payment_signature(params_dict)
            print("[PaymentService] Signature verification SUCCESS")
            return True
        except razorpay.errors.SignatureVerificationError:
            print("[PaymentService] Signature verification FAILED")
            return False
        except Exception as e:
            print(f"[PaymentService] Error during verification: {str(e)}")
            return False

    def verify_webhook_signature(self, body: bytes, signature: str) -> bool:
        """Verifies the Razorpay webhook signature"""
        if not self.client:
            return True # Mock mode
            
        try:
            expected_signature = hmac.new(
                self.webhook_secret.encode('utf-8'),
                body,
                hashlib.sha256
            ).hexdigest()
            return hmac.compare_digest(expected_signature, signature)
        except Exception as e:
            print(f"[PaymentService] Webhook signature verification error: {str(e)}")
            return False
