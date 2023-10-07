// <autogenerated>
//   This file was generated by dddappp code generator.
//   Any changes made to this file manually will be lost next time the file is regenerated.
// </autogenerated>

module rooch_examples::blog {
    use moveos_std::account_storage;
    use moveos_std::event;
    use moveos_std::object_id::ObjectID;
    use moveos_std::context::Context;
    use std::error;
    use std::signer;
    use std::string::String;
    friend rooch_examples::blog_add_article_logic;
    friend rooch_examples::blog_remove_article_logic;
    friend rooch_examples::blog_create_logic;
    friend rooch_examples::blog_update_logic;
    friend rooch_examples::blog_delete_logic;
    friend rooch_examples::blog_aggregate;

    const ErrorDataTooLong: u64 = 102;
    const ErrorInappropriateVersion: u64 = 103;
    const ErrorNotGenesisAccount: u64 = 105;

    struct Blog has key, store {
        version: u64,
        name: String,
        articles: vector<ObjectID>,
    }

    public fun version(blog: &Blog): u64 {
        blog.version
    }

    public fun name(blog: &Blog): String {
        blog.name
    }

    public(friend) fun set_name(blog: &mut Blog, name: String) {
        assert!(std::string::length(&name) <= 200, ErrorDataTooLong);
        blog.name = name;
    }

    public fun articles(blog: &Blog): vector<ObjectID> {
        blog.articles
    }

    public(friend) fun set_articles(blog: &mut Blog, articles: vector<ObjectID>) {
        blog.articles = articles;
    }

    public(friend) fun new_blog(
        name: String,
        articles: vector<ObjectID>,
    ): Blog {
        assert!(std::string::length(&name) <= 200, ErrorDataTooLong);
        Blog {
            version: 0,
            name,
            articles,
        }
    }

    struct ArticleAddedToBlog has key {
        version: u64,
        article_id: ObjectID,
    }

    public fun article_added_to_blog_article_id(article_added_to_blog: &ArticleAddedToBlog): ObjectID {
        article_added_to_blog.article_id
    }

    public(friend) fun new_article_added_to_blog(
        blog: &Blog,
        article_id: ObjectID,
    ): ArticleAddedToBlog {
        ArticleAddedToBlog {
            version: version(blog),
            article_id,
        }
    }

    struct ArticleRemovedFromBlog has key {
        version: u64,
        article_id: ObjectID,
    }

    public fun article_removed_from_blog_article_id(article_removed_from_blog: &ArticleRemovedFromBlog): ObjectID {
        article_removed_from_blog.article_id
    }

    public(friend) fun new_article_removed_from_blog(
        blog: &Blog,
        article_id: ObjectID,
    ): ArticleRemovedFromBlog {
        ArticleRemovedFromBlog {
            version: version(blog),
            article_id,
        }
    }

    struct BlogCreated has key {
        name: String,
        articles: vector<ObjectID>,
    }

    public fun blog_created_name(blog_created: &BlogCreated): String {
        blog_created.name
    }

    public fun blog_created_articles(blog_created: &BlogCreated): vector<ObjectID> {
        blog_created.articles
    }

    public(friend) fun new_blog_created(
        name: String,
        articles: vector<ObjectID>,
    ): BlogCreated {
        BlogCreated {
            name,
            articles,
        }
    }

    struct BlogUpdated has key {
        version: u64,
        name: String,
        articles: vector<ObjectID>,
    }

    public fun blog_updated_name(blog_updated: &BlogUpdated): String {
        blog_updated.name
    }

    public fun blog_updated_articles(blog_updated: &BlogUpdated): vector<ObjectID> {
        blog_updated.articles
    }

    public(friend) fun new_blog_updated(
        blog: &Blog,
        name: String,
        articles: vector<ObjectID>,
    ): BlogUpdated {
        BlogUpdated {
            version: version(blog),
            name,
            articles,
        }
    }

    struct BlogDeleted has key {
        version: u64,
    }

    public(friend) fun new_blog_deleted(
        blog: &Blog,
    ): BlogDeleted {
        BlogDeleted {
            version: version(blog),
        }
    }


    public(friend) fun update_version_and_add(storage_ctx: &mut Context, account: &signer, blog: Blog) {
        assert!(signer::address_of(account) == @rooch_examples, error::invalid_argument(ErrorNotGenesisAccount));
        blog.version = blog.version + 1;
        private_add_blog(storage_ctx, account, blog);
    }

    public(friend) fun remove_blog(storage_ctx: &mut Context): Blog {
        account_storage::global_move_from<Blog>(storage_ctx, @rooch_examples)
    }

    public(friend) fun add_blog(storage_ctx: &mut Context, account: &signer, blog: Blog) {
        assert!(signer::address_of(account) == @rooch_examples, error::invalid_argument(ErrorNotGenesisAccount));
        assert!(blog.version == 0, ErrorInappropriateVersion);
        private_add_blog(storage_ctx, account, blog);
    }

    fun private_add_blog(storage_ctx: &mut Context, account: &signer, blog: Blog) {
        assert!(std::string::length(&blog.name) <= 200, ErrorDataTooLong);
        account_storage::global_move_to(storage_ctx, account, blog);
    }

    public(friend) fun drop_blog(blog: Blog) {
        let Blog {
            version: _version,
            name: _name,
            articles: _articles,
        } = blog;
    }

    public(friend) fun borrow_mut_blog(storage_ctx: &mut Context): &mut Blog {
        account_storage::global_borrow_mut<Blog>(storage_ctx, @rooch_examples)
    }

    public fun borrow_blog(storage_ctx: &mut Context): &Blog {
        account_storage::global_borrow<Blog>(storage_ctx, @rooch_examples)
    }

    public(friend) fun update_version(blog: &mut Blog) {
        blog.version = blog.version + 1;
    }

    public(friend) fun emit_article_added_to_blog(storage_ctx: &mut Context, article_added_to_blog: ArticleAddedToBlog) {
        event::emit(storage_ctx, article_added_to_blog);
    }

    public(friend) fun emit_article_removed_from_blog(storage_ctx: &mut Context, article_removed_from_blog: ArticleRemovedFromBlog) {
        event::emit(storage_ctx, article_removed_from_blog);
    }

    public(friend) fun emit_blog_created(storage_ctx: &mut Context, blog_created: BlogCreated) {
        event::emit(storage_ctx, blog_created);
    }

    public(friend) fun emit_blog_updated(storage_ctx: &mut Context, blog_updated: BlogUpdated) {
        event::emit(storage_ctx, blog_updated);
    }

    public(friend) fun emit_blog_deleted(storage_ctx: &mut Context, blog_deleted: BlogDeleted) {
        event::emit(storage_ctx, blog_deleted);
    }

}
