module Spree
  class Order
    module GiftCard
      extend ActiveSupport::Concern

      def add_gift_card_payments(gift_card)
        payments.gift_cards.checkout.map(&:invalidate!)

        if gift_card.present?
          payment_method = Spree::PaymentMethod::GiftCard.available.first
          raise "Gift Card payment method could not be found" unless payment_method

          amount_to_take = gift_card_amount(gift_card, outstanding_balance)
          create_gift_card_payment(payment_method, gift_card, amount_to_take)
        end
      end

      def total_applied_gift_card
        payments.gift_cards.valid.sum(:amount)
      end

      def using_gift_card?
        total_applied_gift_card > 0
      end

      def display_total_applied_gift_card
        Spree::Money.new(-total_applied_gift_card, currency: currency)
      end

      def total_after_gift_card
        total - total_applied_gift_card
      end

      private

        def create_gift_card_payment(payment_method, gift_card, amount)
          payments.create!(
            source: gift_card,
            payment_method: payment_method,
            amount: amount,
            state: 'checkout',
            response_code: gift_card.generate_authorization_code
          )
        end

        def gift_card_amount(gift_card, total)
          [gift_card.amount_remaining, total].min
        end
    end
  end
end