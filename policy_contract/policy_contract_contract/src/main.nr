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
        last_reset_timestamp: Owned<PrivateMutable<UintNote, Context>, Context>,
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

        let current_timestamp =
            self.context.get_anchor_block_header().timestamp();

        self.storage
            .last_reset_timestamp
            .at(owner)
            .initialize(UintNote {
                value: current_timestamp as u128,
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
         * Current block timestamp.
         */
        let current_timestamp =
            self.context.get_anchor_block_header().timestamp();

        /*
         * Read and recreate the daily limit note.
         */
        let limit_message = self
            .storage
            .daily_limit
            .at(owner)
            .get_note();

        let limit_value = limit_message.get_note().value;

        limit_message
            .deliver(MessageDelivery::onchain_constrained());

        /*
         * Read and recreate the last reset timestamp note.
         */
        let reset_message = self
            .storage
            .last_reset_timestamp
            .at(owner)
            .get_note();

        let last_reset_timestamp =
            reset_message.get_note().value as u64;

        reset_message
            .deliver(MessageDelivery::onchain_constrained());

        /*
         * Check whether 24 hours have passed.
         *
         * 24 hours = 86400 seconds.
         */
        let reset_required =
            current_timestamp >= last_reset_timestamp + 86400;

        if reset_required {
            /*
             * Start a new spending period.
             */
            self.storage
                .last_reset_timestamp
                .at(owner)
                .replace(|_old_timestamp| {
                    UintNote {
                        value: current_timestamp as u128,
                    }
                })
                .deliver(MessageDelivery::onchain_constrained());

            /*
             * Since this is a new day, the current spend becomes
             * the first spend of the new period.
             */
            self.storage
                .spent_today
                .at(owner)
                .replace(|_old_spent| {
                    assert(
                        amount <= limit_value,
                        "Daily spending limit exceeded",
                    );

                    UintNote {
                        value: amount,
                    }
                })
                .deliver(MessageDelivery::onchain_constrained());
        } else {
            /*
             * Same 24-hour period.
             *
             * Add this amount to the existing cumulative spending.
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
}