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
            .replace(|_old_limit| {
                UintNote {
                    value: new_daily_limit,
                }
            })
            .deliver(MessageDelivery::onchain_constrained());
    }

    #[external("private")]
    fn spend(amount: u128) {
        let owner = self.msg_sender();

        /*
         * Read the current daily limit and recreate it.
         *
         * PrivateMutable::get_note() performs a nullify-and-recreate
         * operation. Using the returned NoteMessage's public get_note()
         * lets us read the UintNote without accessing its private fields.
         */
        let limit_message = self
            .storage
            .daily_limit
            .at(owner)
            .get_note();

        let limit_note = limit_message.get_note();
        let limit_value = limit_note.value;

        /*
         * Preserve the recreated daily-limit note for the next
         * transaction.
         */
        limit_message.deliver(MessageDelivery::onchain_constrained());

        /*
         * Update cumulative spending.
         *
         * The previous spent_today note is consumed and replaced
         * with the new cumulative value.
         */
        self.storage
            .spent_today
            .at(owner)
            .replace(|old_spent| {
                let new_spent = old_spent.value + amount;

                assert(
                    new_spent <= limit_value,
                    "Daily spending limit exceeded",
                );

                UintNote {
                    value: new_spent,
                }
            })
            .deliver(MessageDelivery::onchain_constrained());
    }
}