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
            .initialize(UintNote { value: daily_limit })
            .deliver(MessageDelivery::onchain_constrained());

        self.storage
            .spent_today
            .at(owner)
            .initialize(UintNote { value: 0 })
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

        self.storage
            .daily_limit
            .at(owner)
            .replace(|limit_note| {
                self.storage
                    .spent_today
                    .at(owner)
                    .replace(|spent_note| {
                        let new_spent = spent_note.value + amount;

                        assert(
                            new_spent <= limit_note.value,
                            "Daily spending limit exceeded",
                        );

                        UintNote {
                            value: new_spent,
                        }
                    })
                    .deliver(MessageDelivery::onchain_constrained());

                limit_note
            })
            .deliver(MessageDelivery::onchain_constrained());
    }
}