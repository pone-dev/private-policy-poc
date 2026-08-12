use aztec::macros::aztec;

#[aztec]
pub contract Main {
    use aztec::{
        macros::{
            functions::{external, initializer},
            storage::storage,
        },
        messages::delivery::MessageDelivery,
        state_vars::{Owned, PrivateMutable},
    };

    use uint_note::UintNote;

    #[storage]
    struct Storage<Context> {
        daily_limit: Owned<PrivateMutable<UintNote, Context>, Context>,
        spent_today: Owned<PrivateMutable<UintNote, Context>, Context>,
    }

    #[initializer]
    #[external("private")]
    fn constructor() {}

    #[external("private")]
    fn initialize_policy(daily_limit: u128) {
        let owner = self.msg_sender();

        self.storage
            .daily_limit
            .at(owner)
            .initialize(UintNote {
                value: daily_limit,
            })
            .deliver(MessageDelivery::onchain_constrained());

        self.storage
            .spent_today
            .at(owner)
            .initialize(UintNote {
                value: 0,
            })
            .deliver(MessageDelivery::onchain_constrained());
    }

    #[external("private")]
    fn update_policy(new_daily_limit: u128) {
        let owner = self.msg_sender();

        self.storage
            .daily_limit
            .at(owner)
            .replace(|_old_note| {
                UintNote {
                    value: new_daily_limit,
                }
            })
            .deliver(MessageDelivery::onchain_constrained());
    }

    #[external("private")]
    fn spend(amount: u128) {
        let owner = self.msg_sender();

        // Read the current daily limit.
        //
        // PrivateMutable::get_note() consumes the current note and
        // creates a replacement note. We MUST deliver that replacement
        // so the daily limit remains available for the next transaction.
        let current_limit = self
            .storage
            .daily_limit
            .at(owner)
            .get_note();

        let limit_note = current_limit.get_note();

        // Preserve the daily-limit note for future transactions.
        current_limit.deliver(MessageDelivery::onchain_constrained());

        // Update the cumulative spending amount.
        //
        // replace() consumes the current spent note and creates the
        // replacement note with the new cumulative value.
        self.storage
            .spent_today
            .at(owner)
            .replace(|old_spent| {
                let new_spent = old_spent.value + amount;

                assert(
                    new_spent <= limit_note.value,
                    "Daily spending limit exceeded",
                );

                UintNote {
                    value: new_spent,
                }
            })
            .deliver(MessageDelivery::onchain_constrained());
    }
}