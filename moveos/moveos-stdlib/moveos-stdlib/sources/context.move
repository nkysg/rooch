/// Context is part of the StorageAbstraction
/// It is used to provide a context for the storage operations, make the storage abstraction, 
/// and let developers can customize the storage

module moveos_std::context {

    use std::option::Option;
    use moveos_std::storage_context::{Self, StorageContext};
    use moveos_std::tx_context::{Self, TxContext};
    use moveos_std::object_id::ObjectID;
    use moveos_std::object::Object;
    use moveos_std::tx_meta::{TxMeta};
    use moveos_std::tx_result::{TxResult};

    #[test_only]
    use moveos_std::test_helper;

    /// Information about the global context include TxContext and StorageContext
    /// We can not put the StorageContext to TxContext, because object module depends on tx_context module,
    /// and storage_context module depends on object module.
    /// We put both TxContext and StorageContext to Context, for convenience of developers.
    /// The Context can not be `drop` or `store`, so developers need to pass the `&Context` or `&mut Context` to the `entry` function.
    struct Context {
        tx_context: TxContext,
        /// The Global Object Storage
        storage_context: StorageContext,
    }

    /// Get an immutable reference to the transaction context from the storage context
    public fun tx_context(self: &Context): &TxContext {
        &self.tx_context
    }

    /// Get a mutable reference to the transaction context from the storage context
    public fun tx_context_mut(self: &mut Context): &mut TxContext {
        &mut self.tx_context
    }

    // Wrap functions for TxContext

    /// Return the address of the user that signed the current transaction
    public fun sender(self: &Context): address {
        tx_context::sender(&self.tx_context)
    } 

    /// Return the sequence number of the current transaction
    public fun sequence_number(self: &Context): u64 {
        tx_context::sequence_number(&self.tx_context)
    }

    /// Return the maximum gas amount that can be used by the current transaction
    public fun max_gas_amount(self: &Context): u64 {
        tx_context::max_gas_amount(&self.tx_context)
    }

    /// Generate a new unique address
    public fun fresh_address(self: &mut Context): address {
        tx_context::fresh_address(&mut self.tx_context)
    }

    /// Generate a new unique object ID
    public fun fresh_object_id(self: &mut Context): ObjectID {
        tx_context::fresh_object_id(&mut self.tx_context)
    }

    /// Return the hash of the current transaction
    public fun tx_hash(self: &Context): vector<u8> {
        tx_context::tx_hash(&self.tx_context)
    } 

    /// Add a value to the context map
    public fun add<T: drop + store + copy>(self: &mut Context, value: T) {
        tx_context::add(&mut self.tx_context, value); 
    }

    /// Get a value from the context map
    public fun get<T: drop + store + copy>(self: &Context): Option<T> {
        tx_context::get(&self.tx_context)
    }

    public fun tx_meta(self: &Context): TxMeta {
        tx_context::tx_meta(&self.tx_context)
    }

    public fun tx_result(self: &Context): TxResult {
        tx_context::tx_result(&self.tx_context)
    }


    // Wrap functions for StorageContext 

    #[private_generics(T)]
    /// Borrow Object from object store with object_id
    public fun borrow_object<T: key>(self: &Context, object_id: ObjectID): &Object<T> {
        storage_context::borrow<T>(&self.storage_context, object_id)
    }

    #[private_generics(T)]
    /// Borrow mut Object from object store with object_id
    public fun borrow_object_mut<T: key>(self: &mut Context, object_id: ObjectID): &mut Object<T> {
        storage_context::borrow_mut<T>(&mut self.storage_context, object_id)
    }

    #[private_generics(T)]
    /// Remove object from object store
    public fun remove_object<T: key>(self: &mut Context, object_id: ObjectID): Object<T> {
        storage_context::remove<T>(&mut self.storage_context, object_id)
    }

    #[private_generics(T)]
    /// Add object to object store
    public fun add_object<T: key>(self: &mut Context, obj: Object<T>) {
        storage_context::add<T>(&mut self.storage_context, obj)
    }

    public fun contains_object(self: &Context, object_id: ObjectID): bool {
        storage_context::contains(&self.storage_context, object_id)
    }

    #[test_only]
    /// Create a Context for unit test
    public fun new_test_context(sender: address): Context {
        // We need to ensure the tx_hash is unique, so we append the sender to the seed
        // If a sender create two Context, the tx_hash will be the same.
        // Maybe the test function need to pass a type parameter as seed.
        let seed = b"test_tx";
        std::vector::append(&mut seed, moveos_std::bcs::to_bytes(&sender));
        new_test_context_random(sender, seed)
    }

    #[test_only]
    /// Create a Context for unit test with random seed
    public fun new_test_context_random(sender: address, seed: vector<u8>): Context {
        let tx_context = tx_context::new_test_context_random(sender, seed);
        let storage_context = storage_context::new_with_id(storage_context::global_object_storage_handle());
        Context {
            tx_context,
            storage_context,
        }
    }

    #[test_only]
    /// Testing only: allow to drop Context
    public fun drop_test_context(self: Context) {
        test_helper::destroy<Context>(self);
    }
}
