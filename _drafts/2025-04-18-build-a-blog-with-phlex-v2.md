---
layout: post
title: Build a Blog with Phlex v2
subtitle: Let's build a basic blog using Phlex with Rails 8.1
tags: rails ruby phlex tailwindcss
date: '2025-04-18'
---

This tutorial will not focus on migrating existing Rails views to Phlex, nor will it focus on the internals of how Phlex works or even how to get the most out of it. Instead, this a pragmatic guide and demonstration of how to use Phlex in a familiar Rails CRUD app.

I will assume you've read at least the first [Overview](https://www.phlex.fun/overview.html) and [Getting Started](https://www.phlex.fun/getting-started.html) sections of the Phlex documentation, and (if you're following along) you've already set up a new Rails app, added `phlex-rails` and `tailwindcss-rails`, run the necessary generators (`rails generate phlex:install`, `rails tailwindcss:install`), and have the Rails welcome page up and running locally.

**Target Audience:** Experienced Ruby/Rails developers new to Phlex.
**Goal:** Build a CRUD blog with Posts and Comments using Phlex views/components and Tailwind CSS.


# Phlex Conventions & Setup

## Phlex Conventions

In Ruby, everything is an `Object`. In Phlex, (almost) everything is a `Component` and a component is a PORO (plain-ol'-Ruby object). Phlex components are Ruby classes that inherit from `Phlex::HTML` (or other subclass of `Phlex::SGML`) which are used to build self-contained reusable UI elements and render them as HTML.

The core proposition of using Phlex is to model the hierarchal structure of an HTML document using Ruby classes and methods, instead of string concatenation. There are other architectural and philosophical implications to this approach (which are covered in the [Phlex Overview](https://www.phlex.fun/overview.html) section of the documentation), but pragmatically speaking, the most important thing to understand is that:

**Phlex components are Ruby classes that define a `view_template` method which returns a block of HTML.**

```ruby
# app/components/components/hello_world.rb
class Components::HelloWorld < Phlex::HTML
  def view_template
    h1 { "Hello, World!" }
  end
end
```

After running the `phlex:install` generator, we end with two modules: `Views` and `Components`, which are the building blocks of our Phlex-based frontend.

* app/
  * components/ - for Phlex *components* (reusable UI elements).
    * base.rb - base class for components; inherits from `Phlex::HTML`.
  * views/ - for Phlex *views* (page-level components).
    * base.rb - base class for views; inherits from `Components::Base`.
* config/
  * initializers/
    * phlex.rb - defines the `Views` and `Components` modules and configures autoloading.
{: .tree}


## Views vs. Components
When using `ActionView` and ERB, we typically break down an HTML document hierarchically into layouts, views, and partials. Rails handles these as separate concepts, but with Phlex there is no such technical distinction; they are all **components**.

A _view_ is therefore just a convention for defining page-level components, rather than being a technical construct.

> In Phlex, a view is really just another component, but views are not typically rendered inside other views. They’re usually the root and they usually start with a doctype and end with `</html>`.\
> [Phlex Docs → Rails → Views](https://www.phlex.fun/rails/views.html)

## View Helpers Adapters

[Phlex defines adapters for all of `ActionView`'s built-in view helpers](https://github.com/phlex-ruby/phlex-rails/tree/main/lib/phlex/rails/helpers). They are not included by default, with the exception of `Phlex::Rails::Helpers::Routes`, which defines methods like `articles_path`, `form_with`, etc.

> None of the adapters are included by default because you probably don’t need that many helpers if you’re using Phlex. For example, do you really need `link_to` when you have `a`?\
> [Phlex Docs → HTML & SVG → Helpers → Built-in adapters](https://www.phlex.fun/rails/helpers.html#built-in-adapters)

```ruby
# app/components/components/base.rb
class Components::Base < Phlex::HTML
  include Components

  # Include Rails route helpers
  include Phlex::Rails::Helpers::Routes

  # Non-default helpers
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::UrlFor
  # ... add more as needed
end
```

## Kits
Now fully supported in v2, [`Phlex::Kit`](https://www.phlex.fun/components/kits.html) provides a shorthand for rendering components, e.g. `Button(...)` instead of `render Button.new(...)`. The `Components` module defined by the Rails generator extends `Phlex::Kit` by default, giving you access to the syntax in your components.

> It’s up to you whether you use Kits or not. They may feel too magical. Capital-letter methods are rare in Ruby. I personally prefer the aesthetic, but it’s your choice.
>
> [Phlex Docs → Components → Kits](https://www.phlex.fun/components/kits.html)

```ruby
# config/initializers/phlex.rb
module Components
  # Include component kit for shorthand rendering within components
  extend Phlex::Kit
end
```


# Building a Layout
Phlex doesn't have a special "layout" handling like Rails does. In Phlex, a layout is simply another component (and remember: components are just POROs). However, we can still borrow the concept of a layout wrapping the page content to create a consistent structure across our views.

In conventional Rails apps, [when a view is rendered from a controller action](https://guides.rubyonrails.org/layouts_and_rendering.html#structuring-layouts), `ActionView` automatically wraps that view's content inside a layout template; we do things like `yield` or call `content_for` to define where exactly a view's content should go.

```erb
<!-- app/views/layouts/application.html.erb -->
<!DOCTYPE html>
<html>
  <head>
    <title>MyApp</title>
  </head>

  <body>
    <header></header>
      <%= yield %> <!-- This is where the view content goes -->
    <footer></footer>
  </body>
```

To define a layout using Phlex, we first want to disable Rails' implicit layout-specific rendering behavior. This is because we do not want `ActionView` to try to wrap our rendered components in an ERB layout template. To do this, we can use the [`:layout` option](https://guides.rubyonrails.org/layouts_and_rendering.html#the-layout-option) in calls to `render` from controller actions, or by call the `layout` class method in `ApplicationController` or its subclasses.

This is what we'll do in `ApplicationController` when using Phlex to manage layouts across our entire app:

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  layout false
end
```

## Layouts via Composition

Because we're working with POROs, we can leverage composition to construct a "layout." Using composition, we'll have our view component (e.g., `Views::Posts::Index`) explicitly render a layout component (e.g., `Components::Layout`) by passing its main content *into* the layout component via a block.

### How it works

* We create a dedicated `Components::Layout` component which defines the overall HTML structure (`<html>`, `<head>`, `<body>`, header, footer) and `yield`s the block passed to it.
* Within a given view component (e.g., `Views::Posts::Index`), we explicitly render the `Layout` component, passing its content via a block.

### Example

```ruby
# app/controllers/home_controller.rb
class PostsController < ApplicationController
  def index
    render Views::Posts::Index.new(name: "World")
  end
end
```

```ruby
# app/views/posts/index.rb
class Views::Posts::Index < Views::Base
  def initialize(name:)
    @name = name
  end

  def view_template
    # Explicitly render the Layout component
    Layout(title: "Welcome Home") do # Using Kit shorthand
      # And pass the page content as a block
      h1 { "Hello, #{@name}!" }
      p { "This is the specific content for the home page." }
    end
  end
end
```

```ruby
# app/components/components/layout.rb
class Components::Layout < Components::Base
  def initialize(title: "Default Title")
    @title = title
  end

  def view_template
    doctype
    html do
      head do
        title { @title }
        stylesheet_link_tag "application", data_turbo_track: "reload"
      end
      body do
        header { nav { link_to "Home", root_path } }
        main(class: "content-area") { yield } # Render the block content here
        footer { plain "My Footer" }
      end
    end
  end
end
```


### Why choose Composition over Inheritance?

* Pros:
  * Explicit: It's very clear in each view exactly which layout is being used and where the content goes.
  * Flexible: Easy to use different layouts for different views just by rendering a different layout component (`AdminLayout(...)`, `PublicLayout(...)`).
  * Simple Concept: Follows standard component rendering patterns. No special hooks needed.
* Cons:
  * Repetitive: You need to type `Layout(...) do ... end` in every single view.

{:.text-sm}
_See [Layouts via Inheritance](#layouts-via-inheritance) in the Appendix for an alternative approach using inheritance._


# Posts CRUD - Setting Up

Let's generate the Post model and controller.

```bash
bundle exec rails g model Post title:string body:text
bundle exec rails db:migrate
bundle exec rails g controller Posts index show new create edit update destroy --skip-routes
```

Add resourceful routes:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  resources :posts
  # Define root_path if not already set
  root "posts#index"
  # ... other routes
end
```

---

# 4. Posts CRUD - Index View

Generate the index view:

```bash
bundle exec rails g phlex:view Posts::Index
```

Implement the controller action:

```ruby
# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def index
    @posts = Post.order(created_at: :desc)
    render Views::Posts::Index.new(posts: @posts)
  end

  # ... other actions
end
```

Implement the Phlex view:

```ruby
# app/views/views/posts/index.rb
class Views::Posts::Index < Views::Base
  def initialize(posts:)
    @posts = posts
  end

  def view_template
    # Use the Layout component defined earlier
    Layout(title: "All Posts") do
      div(class: "flex justify-between items-center mb-6") do
        h1(class: "text-3xl font-bold") { "Blog Posts" }
        # Use link_to helper from Base view/component
        link_to "New Post", new_post_path, class: "bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded"
      end

      # Render a list of posts
      if @posts.any?
        div(class: "space-y-4") do
          @posts.each do |post|
            # Render each post using a dedicated component
            PostCard(post: post) # Using Kit shorthand
          end
        end
      else
        p(class: "text-gray-500") { "No posts yet. Create one!" }
      end
    end
  end
end
```

Now, create the `PostCard` component:

```bash
bundle exec rails g phlex:component PostCard
```

```ruby
# app/components/components/post_card.rb
class Components::PostCard < Components::Base
  def initialize(post:)
    @post = post
  end

  def view_template
    article(class: "bg-white p-6 rounded-lg shadow-md") do
      h2(class: "text-2xl font-semibold mb-2") do
        link_to @post.title, post_path(@post), class: "hover:text-blue-700"
      end
      p(class: "text-gray-600 mb-4") do
        # Truncate body for preview if desired
        plain @post.body.truncate(150)
      end
      div(class: "text-sm text-gray-500") do
        plain "Posted on: #{@post.created_at.strftime('%B %d, %Y')}"
        whitespace # Add space between links
        link_to "Edit", edit_post_path(@post), class: "text-blue-500 hover:underline"
      end
    end
  end

  # Include helpers needed specifically for this component if not in Base
  # include Phlex::Rails::Helpers::Text # For truncate
end
```

**Key Concepts:**
* **Composition:** The `Views::Posts::Index` renders the `Layout` component and passes its content via a block.
* **Component Extraction:** The display logic for a single post is moved into `Components::PostCard`.
* **Kits:** We use `Layout(...)` and `PostCard(...)` directly because `Components::Base` includes the `Components` kit.
* **Helpers:** Rails helpers like `link_to`, `new_post_path`, `post_path` work as expected because we included the necessary `Phlex::Rails::Helpers` modules in our base classes.
* **Styling:** Tailwind classes are applied directly using the `class:` keyword argument.

---

# 5. Posts CRUD - Show View

Generate the show view:

```bash
bundle exec rails g phlex:view Posts::Show
```

Implement the controller action:

```ruby
# app/controllers/posts_controller.rb
  def show
    @post = Post.find(params[:id])
    # We'll add comments later
    render Views::Posts::Show.new(post: @post)
  end
```

Implement the Phlex view:

```ruby
# app/views/views/posts/show.rb
class Views::Posts::Show < Views::Base
  def initialize(post:)
    @post = post
    # @comments = comments # Add later
  end

  def view_template
    Layout(title: @post.title) do
      article(class: "bg-white p-8 rounded-lg shadow-md") do
        h1(class: "text-4xl font-bold mb-4") { @post.title }
        p(class: "text-gray-500 text-sm mb-6") { "Posted on: #{@post.created_at.strftime('%B %d, %Y')}" }

        div(class: "prose max-w-none mb-8") do
          # Assuming body might contain markdown or simple formatting
          # For complex HTML, consider using `raw safe(processed_body)`
          # after sanitization. For simple text:
          plain @post.body
        end

        div(class: "flex space-x-4") do
          link_to "Edit Post", edit_post_path(@post), class: "text-blue-500 hover:underline"
          link_to "Back to Posts", posts_path, class: "text-gray-500 hover:underline"
          # Add delete link later
        end
      end

      # Comments section (add later)
      # div(id: "comments", class: "mt-8") do
      #   h2(class: "text-2xl font-semibold mb-4") { "Comments" }
      #   # ... render comments and form
      # end
    end
  end
end
```

---

# 6. Posts CRUD - Forms (New/Edit)

Handling forms in Phlex often involves using Rails' built-in form helpers (`form_with`, `form_for`) directly within your Phlex components or views.

Generate the views:

```bash
bundle exec rails g phlex:view Posts::New
bundle exec rails g phlex:view Posts::Edit
```

Implement controller actions:

```ruby
# app/controllers/posts_controller.rb
  def new
    @post = Post.new
    render Views::Posts::New.new(post: @post)
  end

  def edit
    @post = Post.find(params[:id])
    render Views::Posts::Edit.new(post: @post)
  end

  def create
    @post = Post.new(post_params)
    if @post.save
      redirect_to @post, notice: "Post was successfully created."
    else
      # Re-render the New view with errors
      render Views::Posts::New.new(post: @post), status: :unprocessable_entity
    end
  end

  def update
    @post = Post.find(params[:id])
    if @post.update(post_params)
      redirect_to @post, notice: "Post was successfully updated."
    else
      # Re-render the Edit view with errors
      render Views::Posts::Edit.new(post: @post), status: :unprocessable_entity
    end
  end

  # ... destroy action ...

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end
```

Now, let's create a reusable form component. This is where Phlex shines over partials for complex, configurable elements.

```bash
bundle exec rails g phlex:component PostForm
```

```ruby
# app/components/components/post_form.rb
class Components::PostForm < Components::Base
  def initialize(post:)
    @post = post
  end

  def view_template
    # form_with comes from Phlex::Rails::Helpers::FormWith included in Base
    form_with(model: @post, class: "space-y-6 bg-white p-8 rounded-lg shadow-md") do |f|
      # Display validation errors
      if @post.errors.any?
        div(class: "bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-6", role: "alert") do
          strong(class: "font-bold") { "Oops! #{pluralize(@post.errors.count, 'error')} prohibited this post from being saved:" }
          ul(class: "mt-3 list-disc list-inside") do
            @post.errors.full_messages.each do |message|
              li { message }
            end
          end
        end
      end

      # Use extracted field components for consistency
      FormField(f: f, attribute: :title, label: "Title") do
        f.text_field :title, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
      end

      FormField(f: f, attribute: :body, label: "Body") do
        f.text_area :body, rows: 10, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-300 focus:ring focus:ring-indigo-200 focus:ring-opacity-50"
      end

      div(class: "flex justify-end") do
        SubmitButton(form: f, text: @post.persisted? ? "Update Post" : "Create Post")
      end
    end
  end

  # Include helpers needed for the form
  include Phlex::Rails::Helpers::Form # For form builders (f) methods like text_field, text_area, submit
  include Phlex::Rails::Helpers::ActionView # For pluralize
end

# --- Extracted Form Field Components ---

class Components::FormField < Components::Base
  def initialize(f:, attribute:, label:)
    @f = f
    @attribute = attribute
    @label = label
  end

  def view_template(&block)
    div(class: "mb-4") do
      @f.label @attribute, @label, class: "block text-sm font-medium text-gray-700"
      # Render the actual input field passed as a block
      render block if block
      # Optionally display errors for this specific field
      field_errors = @f.object.errors[@attribute]
      if field_errors.any?
        p(class: "mt-2 text-sm text-red-600") { field_errors.to_sentence }
      end
    end
  end
end

class Components::SubmitButton < Components::Base
  def initialize(form:, text:)
    @form = form
    @text = text
  end

  def view_template
    @form.submit @text, class: "bg-blue-600 hover:bg-blue-800 text-white font-bold py-2 px-4 rounded cursor-pointer"
  end
end

```

Finally, implement the `New` and `Edit` views using the `PostForm` component:

```ruby
# app/views/views/posts/new.rb
class Views::Posts::New < Views::Base
  def initialize(post:)
    @post = post
  end

  def view_template
    Layout(title: "New Post") do
      h1(class: "text-3xl font-bold mb-6") { "Create New Post" }
      # Render the form component
      PostForm(post: @post)
    end
  end
end
```

```ruby
# app/views/views/posts/edit.rb
class Views::Posts::Edit < Views::Base
  def initialize(post:)
    @post = post
  end

  def view_template
    Layout(title: "Edit Post") do
      h1(class: "text-3xl font-bold mb-6") { "Edit Post" }
      # Render the form component
      PostForm(post: @post)
    end
  end
end
```

**Key Concepts:**
* **Form Helpers:** `form_with` and form builder (`f`) methods work within Phlex.
* **Component Encapsulation:** The entire form structure, including error display and fields, is encapsulated in `Components::PostForm`. Individual fields are further encapsulated in `Components::FormField` and `Components::SubmitButton`.
* **Passing Blocks:** `FormField` accepts the actual input element (`f.text_field`, `f.text_area`) as a block, allowing flexibility while maintaining consistent labeling and error display.
* **Conditional Logic:** Standard Ruby `if` statements are used for error display and button text.

---

# 7. Adding Comments (Briefly)

Let's quickly sketch out adding comments.

Generate model/controller (nested under posts):

```bash
bundle exec rails g model Comment post:references body:text commenter:string
bundle exec rails db:migrate
bundle exec rails g controller Comments create --skip-routes
```

Add nested routes:

```ruby
# config/routes.rb
  resources :posts do
    resources :comments, only: [:create]
  end
```

Update `PostsController#show` to fetch comments:

```ruby
# app/controllers/posts_controller.rb
  def show
    @post = Post.find(params[:id])
    @comments = @post.comments.order(created_at: :asc) # Fetch comments
    # Pass comments to the view
    render Views::Posts::Show.new(post: @post, comments: @comments)
  end
```

Update `CommentsController#create`:

```ruby
# app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  def create
    @post = Post.find(params[:post_id])
    @comment = @post.comments.new(comment_params)
    if @comment.save
      redirect_to @post, notice: "Comment added."
    else
      # Need to re-render the post show page with the comment object containing errors
      # Fetch comments again for re-render
      @comments = @post.comments.order(created_at: :asc)
      # You might flash errors or pass @comment back to the view for display
      flash.now[:alert] = "Comment could not be saved: #{@comment.errors.full_messages.join(', ')}"
      # Re-render the Post Show view
      render "views/posts/show", locals: { post: @post, comments: @comments, new_comment: @comment }, status: :unprocessable_entity
      # Note: Standard render might not work directly with Phlex instances easily here.
      # A common pattern is to render the ERB template associated with `posts/show`
      # OR handle errors via Turbo Streams / JS if you want a pure Phlex render flow.
      # For simplicity here, we'll rely on flash. A better approach involves more setup.
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:commenter, :body)
  end
end
```

Generate `Comment` and `CommentForm` components:

```bash
bundle exec rails g phlex:component Comment
bundle exec rails g phlex:component CommentForm
```

Implement `Components::Comment`:

```ruby
# app/components/components/comment.rb
class Components::Comment < Components::Base
  def initialize(comment:)
    @comment = comment
  end

  def view_template
    div(class: "bg-gray-50 p-4 rounded-md border border-gray-200") do
      p(class: "font-semibold text-gray-800") { @comment.commenter || "Anonymous" }
      p(class: "text-gray-600 mt-1") { @comment.body }
      p(class: "text-xs text-gray-400 mt-2") { "Posted on: #{@comment.created_at.strftime('%c')}" }
    end
  end
end
```

Implement `Components::CommentForm`:

```ruby
# app/components/components/comment_form.rb
class Components::CommentForm < Components::Base
  # Pass the parent post and a potentially new comment object (for errors)
  def initialize(post:, comment: nil)
    @post = post
    # Use provided comment or build a new one for the form
    @comment = comment || @post.comments.new
  end

  def view_template
    # Note: The path needs the parent post: [@post, @comment]
    form_with(model: [@post, @comment], class: "mt-6 space-y-4 bg-white p-6 rounded-lg shadow") do |f|
       # Display form errors if @comment has them (passed back from controller)
       if @comment.errors.any?
         div(class: "bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4", role: "alert") do
           strong(class: "font-bold") { "Could not save comment:" }
           ul(class: "mt-2 list-disc list-inside text-sm") do
             @comment.errors.full_messages.each { |msg| li { msg } }
           end
         end
       end

      FormField(f: f, attribute: :commenter, label: "Your Name") do
        f.text_field :commenter, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm"
      end

      FormField(f: f, attribute: :body, label: "Your Comment") do
        f.text_area :body, rows: 4, required: true, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm"
      end

      div(class: "flex justify-end") do
        SubmitButton(form: f, text: "Add Comment")
      end
    end
  end

  # Include necessary helpers
  include Phlex::Rails::Helpers::Form
  include Phlex::Rails::Helpers::FormWith
end
```

Update `Views::Posts::Show` to use these components:

```ruby
# app/views/views/posts/show.rb
class Views::Posts::Show < Views::Base
  # Accept comments and potentially a new_comment object with errors
  def initialize(post:, comments: [], new_comment: nil)
    @post = post
    @comments = comments
    @new_comment = new_comment # For rendering the form with errors
  end

  def view_template
    Layout(title: @post.title) do
      # ... (post article rendering as before) ...

      # Comments section
      section(id: "comments", class: "mt-12") do
        h2(class: "text-2xl font-semibold mb-6 border-b pb-2") { "Comments (#{@comments.count})" }

        # Display existing comments
        if @comments.any?
          div(class: "space-y-4 mb-8") do
            @comments.each do |comment|
              Comment(comment: comment) # Render comment component
            end
          end
        else
          p(class: "text-gray-500 mb-8") { "Be the first to comment!" }
        end

        # Add comment form
        h3(class: "text-xl font-semibold mb-4") { "Leave a Comment" }
        # Pass the post and the @new_comment object (which might have errors)
        CommentForm(post: @post, comment: @new_comment)
      end
    end
  end
end
```

**Note on Controller Re-rendering:** Re-rendering a Phlex view instance directly from the controller on validation failure (`render Views::Posts::Show.new(...)`) can be tricky because the instance state might not perfectly match what's needed. Using standard Rails `render template: "posts/show"` with `locals:` or handling errors via Turbo Streams are often more robust patterns when mixing Phlex views with standard controller flows, especially for form errors. The example above simplifies this by relying on flash or passing the `@new_comment` object back for the form component to use.

---

# 8. Conclusion & Next Steps

We've built a basic CRUD blog application using Phlex for views and components within a standard Rails structure.

**Key Takeaways for Rails Developers:**

* **Object-Oriented Views:** Views and UI elements are Ruby classes, promoting encapsulation and testability.
* **Clear Separation:** `app/views` for page-level structures, `app/components` for reusable UI bits.
* **Layouts as Components:** Layouts are typically handled by composition (rendering a `Layout` component within your view) or inheritance (using `around_template` in a base view).
* **Helper Integration:** `phlex-rails` provides adapters (`Phlex::Rails::Helpers::*`) to seamlessly use familiar Rails helpers. Remember to include them in your base classes.
* **Kits:** Use `extend Phlex::Kit` on your `Components` module for the convenient `ComponentName(...)` rendering syntax.
* **Styling:** Apply CSS classes (like Tailwind) directly using the `class:` keyword argument in your Phlex element methods. Manage complexity with arrays, component props, or helper methods within the component.
* **Forms:** Rails form helpers (`form_with`, `f.text_field`, etc.) work well inside Phlex `view_template` methods. Extracting form elements into components enhances reusability.

This tutorial covers the basics. Explore further Phlex features like:

* **Yielding Interfaces:** Creating components with custom DSLs (like the Table example in the Phlex docs).
* **Caching:** Fragment caching (`cache` method) for performance.
* **Streaming:** Improving TTFB for complex pages.
* **SVG:** Building SVG graphics with Phlex.
* **Literal Properties:** Reducing boilerplate for component initializers.


# Appendix

## Layouts via Inheritance
As mentioned earlier, there are two design approaches for implementing layouts within a pure Phlex structure (plus a compatibility option for older Rails layouts not covered here):

2.  **Inheritance:** A specific view component inherits from a base view class (e.g., `Views::Base`) which defines the layout structure and uses a hook (like `around_template` or `super`) to insert the specific view's content.

Let's look at each with an example and discuss the trade-offs.

## Layouts via Inheritance (Base View Renders Layout)

### How it works

* We define a base view class (e.g., `Views::Base` or a dedicated `Views::ApplicationLayout`) that contains the layout logic.
* This base class uses `around_template` (or defines `view_template` and expects subclasses to call `super`) to wrap the specific content.
* Specific individual views (e.g., `Views::HomePage`) inherit from this base class and only need to define their specific content within `view_template`.

### Example

```ruby
# app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    render Views::HomePageInherited.new(name: "World Inherited")
  end
end
```

```ruby
# app/views/views/home_page_inherited.rb
# Inherit from the base class that defines the layout
class Views::HomePageInherited < Views::BaseWithLayout
  def initialize(name:)
    @name = name
  end

  # Define ONLY the specific content for this page
  def view_template
    h1 { "Hello, #{@name}!" }
    p { "This is the specific content for the home page (inherited layout)." }
  end

  # Override the page_title method from the base class
  def page_title
    "Welcome Home (Inherited)"
  end
end
```

```ruby
# app/views/views/base_with_layout.rb
# This acts as our layout-defining base class
class Views::BaseWithLayout < Phlex::HTML # Or inherit from Views::Base if that exists and has helpers
  # Include necessary helpers and the Component Kit
  include Components

  # This hook wraps the subclass's view_template call
  def around_template(&block)
    doctype
    html do
      head do
        title { page_title } # Subclass can override this method to set a custom title
        stylesheet_link_tag "application", data_turbo_track: "reload"
      end
      body do
        header { nav { link_to "Home", root_path } }

        main(class: "content-area") { super } # Ensure inherited hooks are called
        # Phlex::SGML#around_template will call `view_template` on the subclass

        footer { plain "My Footer" }
      end
    end
  end

  # Default title, subclasses can override this
  def page_title
    "Default Title (Inherited)"
  end
end
```

Why choose Inheritance?

* Pros:
    * DRY: Views are cleaner as they don't need to explicitly render the layout component.
    * Enforces Consistency: Ensures all views inheriting from the base use the same layout structure.
    * Centralized Logic: Layout changes are made in one place (the base class).
* Cons:
    * Implicit: It might be less obvious where the layout is coming from if you're just looking at the specific view file. Requires understanding the inheritance chain and hooks like `around_template`.
    * Less Flexible: Using different layouts requires different base classes or more complex logic within the base class, which can get complicated.


## Which Approach Should You Choose?

* **Start with Composition:** If you're new to Phlex or prefer explicitness, composition is usually easier to understand and manage initially. It keeps concerns clearly separated.
* **Consider Inheritance for DRYness:** If you find yourself repeating the `Layout(...) do ... end` structure everywhere and want to enforce a single layout structure across many views, the inheritance approach can reduce boilerplate in your individual view files. Be mindful that it adds a layer of abstraction.
* **Use Legacy Compatibility for Migration:** Only use `Phlex::Rails::Layout` if you need to integrate Phlex layouts with existing non-Phlex views during a transition period.

Let's move on to building our blog application using the composition approach for clarity.
