
# Implement “auth system” for phoenix in 6 steps!

 
## Introduction

One of the essential steps in implementing systems is to build a fast and simple auth system that is sure to be implemented in many programming communities. But each requires a separate configuration as well as a custom database structure, and in fact I want to put it simply, writing the section from the beginning.

For this purpose, to prevent the login section of each project from being created each time, I prepared my personal code in the form of a package with several strategies including “auth2” as well as the custom steps required in a system and a bit of optimization and in the final step I also published the open source. 

 

## Goal

The goal of this project is to facilitate the implementation of an “auth” system and in the future access levels for elixir users who want to work on Phoenix. 

Creating a migration database with a task

Controller implementation with a few simple plug only on call

Implement social networks for registration - extract basic and login information

Implement three strategies (user ID session - token session - and token refresh for external apps)

Implement direct registration and login

 

Are among the items that can be mentioned in this plugin. It needs to be pointed that this plugin is tested with phoenix liveview library and can also work for you customizably. 

 

*It should also be noted that if you do not even want to use this plugin fully, it can still be a help to implement your personal system because of the configuration of several important and popular plugins in Elixir in the structure of a plugin.*

 

## Roadmap

In the first version of this plugin just tried to prioritize the system implementation to a large extent and open a good way to turn from a plugin into a good and comprehensive component for implementing an access level and loging system by connecting popular scripts and social networks.

 

Therefore, in the future, all my efforts will be in developing this system as a self-provider. To this end, many technologies will be added to this simple plugin, and many of the plugins currently in use may be rewritten as dependencies.

 

One of the top priorities in the future is to build a version of the plugin with minimal external dependency. For example, instead of PostGress, the Run Time Erlang database may be used, and it is possible to use the Elixir itself instead of Redis. This is very important for testing as well as for people with limited resources, and I personally understand this need and am researching and implementing it.

 

The small features that are currently being implemented in the next version, as well as you are currently able to write your own manually, which should be mentioned again, this plugin is helpful as follows:

1. Change password

2. Password reset

3. User list for admin

4. Build additional data storage profiles

5. List of created tokens

6. Multi-token support in the system

7. Captcha implementation (freedom to choose between multiple systems)

8. Multi-step activation by email

9. Multi-step activation by SMS

And other items that will be added to this post over time.

 

## Getting to know MishkaAuth plugin

It should be noted the plugin in its core with three general strategies namely works

```elixir
@strategies  ["current_token", "current_user", "refresh_token"]
```

That the two strategies  `current_token`  and   `current_user`  are for rendering html and  `refresh_token`  also For a script or an app outside of your website, the connection path is also  `Json‍`   by default, which is possible with a little touch of the plugin if you need other outputs.

 

Strategies that contain  `token`   themselves generally use Redis, as well as  `jwt`   for digital signature encryption. So one of the required dependencies in the Redis system is that it must be configured on your server, and also for storing user information from social networks temporarily, again Radis and finally for storing user and information related to each Its identity is also in PostGress, which can be opened on other supported items with a small change in  `Ecto`  !!

After implementing your desired strategy, you can now implement this system in two ways on the website. Of course, it should be noted that both of the following steps can be enabled in parallel on your website, you do not need to disable it.

 

### Step one: Register and login from social networks

For the initial testing of the current two social networks, Google and GiteHub, login and registration in the system are provided by default. So in the future, the number of these networks will increase and you just need to get the  `token`  of these social networks from their websites and configure them, and there is no need to do anything else.

 

### Step two: register with the form on the website or Json Api in the controller

If you do not want to use social networks or you want to give the user more choice, it is still enough to create a simple  **html**  form and all the rest is just calling a function.


Due to the use of tokens in most systems for total deletion or separately based on your desired strategies, a few simple functions have been created that will be introduced to you in the following.

 

### Installation and implementation of the required configuration

### 1. creating a new project

The first step is to build a new project, and if you already have a project that you do not need to build, but you need to transfer your users to the new system with a few simple elixir commands or try to integrate with both systems, the personal system and Make this system work.

```
mix phx.new your_project
```

 

### 2. Introducing this plugin in your project mix file

In this step you just need to add  `MishkaAuth`  plugin in file  `mix`  and  `deps`  function.

```elixir
defp deps  do

  [

 ....

 {:mishka_auth, "~> 0.0.1", hex: :plug_mishka_auth}

 ....

  ]

End
```

then add mix deps.get command and done. Now download the plugin and all its related dependencies and click on your project. Now it's time for you to add the configuration for this plugin to your project in the next step.

### 3. adding the related configuration to the plugin.

At the beginning of this section, I have to mention that the configurations are required for several plugins used in  **MishkaAuth** . I am trying to integrate these in the future, but in the next few versions I am only going to work on features and problem solving. But overall it is very simple.

You just need to open the config.exs file and add the following commands in the line above the import_config "#{Mix.env()}.exs"

In the first step, the social networks that you want to configure, for example for GiteHub and Google, are as follows:

```elixir
config :ueberauth, Ueberauth,

base_path: "/auth",

providers: [

  github: {Ueberauth.Strategy.Github, [default_scope: "read:user", send_redirect_uri: false]},

  google: {Ueberauth.Strategy.Google, [default_scope: "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"]},

]
```

In the above cases, based on the required access from these two sites, we extract the basic information, of course, after user approval

And in the next step, you return to the site and enter the information related to your api, including the private key and ID, which is different according to each social network. All you have to do is search on their site and easily get the relevant information. For example, you need to go to the Google Developer Console section for Google.

```elixir
config :ueberauth, Ueberauth.Strategy.Github.OAuth,

client_id: "CLIENT_ID",

client_secret: "SECRET_KEY",

 

config :ueberauth, Ueberauth.Strategy.Google.OAuth,

client_id: "CLIENT_ID",

client_secret: "SECRET_KEY",

redirect_uri: [http://YOUR_DOMAIN_URL/auth/google/callbacktest](http://your_domain_url/auth/google/callbacktest)
```

In the next step, all you have to do is determine the type of password and its size based on the server resources as well as your needs.

```elixir
config :mishka_auth, MishkaAuth.Guardian,

issuer: "mishka_auth",

allowed_algos: ["ES512"],

secret_key: %{Your secret Key}

```

For example, I chose ES512, which is not really needed, and you can use less of it. To create a private key for jwt, you can see this tutorial in the forum, just see this command.

```
JOSE.JWS.generate_key(%{"alg" => "ES512"}) |> JOSE.JWK.to_map |> elem(1)
```

 

The Persian tutorial link: https://devheroes.club/t/guardian/1584

You can put the above output instead of Your Secret Key. Finally, add the following configurations:

```elixir
config :mishka_auth, MishkaAuth,

repo: YOUR_REPO_MODULE,

login_redirect: "/",

user_redirect_path: "/",

authenticated_msg: "Successfully authenticated.",

token_table: "user_token",

refresh_token_table: "refresh_user_token",

access_token_table: "access_token",

user_refresh_token_expire_time: 18000, #5 hour

user_access_token_expire_time: 600, #10 min

user_jwt_token_expire_time: 6000, #10 min

temporary_table: "temporary_user_data",

redix: "Your redis Paswword",

changeset_redirect_view: YOUR_AUTH_VIEW_MODULE,

changeset_redirect_html: "index.html",

register_data_view: YOUR_AUTH_VIEW_MODULE,

register_data_html: "index.html",

automatic_registration: true,

pub_sub: YOUR_PROJECT_PubSub
```


The above configuration is very simple, it opens your hand more than specifying any page you want to redirect or any repo you want, as well as getting notification from your own PubSub module in the future, as well as your file redirect password.

From above, they are as follows:

1. Repo module used in your project

2. Where to redirect after logging in

3. Where to redirect after an error

4. Message related to successful registration with login

5. Radar table for token token strategy (does not need to be changed but will change based on your decision)

6. The name of the token refresh table is like option 5

7. Expiration time token refresh token

8. Exx token expiration time

9. Carnet token expiration time

10. Temporary information table temporary storage name

11. Redis password

12. View module that must be redirected after error in data storage

13. Like option 12, now the name of the desired html file

14. Auto-save after logging in from the social network or displaying information on the form and allowing the user to edit

15. Introducing the pub_sub module (will be used in the future, but please introduce it)

 

90% of all the work that had to be done was done.

 

### 4. creating database

Just hit the following command on your console in the project path

```elixir
mix mishka_auth.db.gen.migration
```


 

After the above command was executed without any problems, now you can easily type the following command and that's it

```
mix ecto.migrate
```

 

### 5- Implementing routers and controllers

This section is an additional item that can be done based on your needs, but it has a few default functions that can be placed in any way you want. It did not support and I pushed it away and the reason for using this plugin was that it has been developed for a long time and it is very popular, but if it bothers you in the future, it will be completely rewritten in the project, but in my tests there are no problems. It was not and it does a very pleasant job.

Assuming that our login and registration form is in the action index function, it is enough to just write that it has nothing to do with the Mishka plugin, but it is related to Ecto and storage in the database.

```
def index(conn, _params) do

 changeset = MishkaAuth.Client.Users.ClientUserSchema.changeset(%MishkaAuth.Client.Users.ClientUserSchema{}, %{})

 render(conn, "index.html", changeset: changeset)

end
```

Assuming that you want the registration to be posted somewhere on the top page, or you want the api to go to an information function and the registration is done, all you have to do is enter this function, it doesn't matter what you want to call it, like the above.

```elixir
def register (conn, %{"client_user_schema" => client_user_schema}) do

 MishkaAuth.Helper.HandleDirectRequest.register(conn, client_user_schema, :normal, :html)

end
```

As I said at the beginning of this article, we have two methods, one direct and one social networking. The above are all straightforward.

Now it's time for direct login, which is based on a half-password user or password email, which has two functions as follows:

```elixir
  def login(conn, %{"password" => password, "email" => email}) do
    MishkaAuth.login_with_email(:current_token, conn, email, password)
  end


  def login(conn, %{"password" => password, "username" => username}) do
    MishkaAuth.login_with_username(:current_user, conn, username, password)
  end
```

 

**Note:**  put this alias MishkaAuthPhxWeb.Router.Helpers above your controller and if you want, you can use guard for each function. For example, I put the desired strategies in a global variable such as: `@strategies ["current_token", "current_user", "refresh_token"]`

 

Now it's time for some of the Guard’s default functions to log in or register on social media

```elixir
def request(conn, %{"strategy" => strategy, "provider" => _provider}) when strategy in @strategies do
    render(conn, "request.html", callback_url: MishkaAuth.callback_url(conn))
end
```

you can not only use “when” my friends and other factors are only used to show that the function does not force you.

**Remarks:**

This is a function called custom. A function that you return to after the social network, so its name can be changed and you must name this router connected to this function.

```elixir
def callbacktest(conn, %{"code" => code, "provider" => provider}) do
    MishkaAuth.handle_callback(conn, Helpers, :auth_path, code, provider)
end
```

In fact, this function helps you to give your desired strategies to callbacks and achieve your preferred result.

At the end of the callback function which dirty coded and you can use it here in multiple functions or put a gaurd for the function or anything else; I just wanted to show it for better understanding.

```elixir
def callback(%{assigns: %{ueberauth_failure: fails}} = conn, %{"provider" => _provider, "code" => _code, "strategy" => strategy}) do
  case strategy do
    "current_token" ->
      MishkaAuth.handle_social(conn, fails, :fails, :current_token)
    "current_user" ->
      MishkaAuth.handle_social(conn, fails, :fails, :current_user)
    "refresh_token" ->
      MishkaAuth.handle_social(conn, fails, :fails, :refresh_token)
  end
end

def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => _provider, "code" => _code, "strategy" => strategy}) do
  case strategy do
    "current_token" ->
      MishkaAuth.handle_social(conn, auth, :auth, :current_token)
    "current_user" ->
      MishkaAuth.handle_social(conn, auth, :auth, :current_user)
    "refresh_token" ->
      MishkaAuth.handle_social(conn, auth, :auth, :refresh_token)
  end
end
```

the first function is for error and the second is if it’s okay to go to the next level. Now we just have to add the routers and thats’ it.

For the form page that you know how to create a router but it can be as the following:

```elixir
scope "/", MishkaAuthPhxWeb  do

 pipe_through :browser

 get "/", AuthController, :index

end
```

the path “/” of a page for example form login can take any address and is customizable. And at the end we introduced the router related to the above functions. 

```elixir
scope "/auth", MishkaAuthPhxWeb  do

 pipe_through :browser

 post("/login", AuthController, :login)

 post("/register", AuthController, :register)

 get("/:provider", AuthController, :request)

 get("/:provider/callbacktest", AuthController, :callbacktest)

 get("/:provider/callback", AuthController, :callback)

end
```

of the above routers (login, register and callbacktest) are changeable to any path and name but the next two items are not. 

 

### 6. time to test

The work is completely done and you no longer need anything and the system has been implemented. If you want to be more comfortable, to force the user to enter the website, we have prepared a few plug-ins for the router that you can use in the controller if you are very tired and not feeling well.

Before introducing the mentioned plugs please put these 3 lines above your controllers, under the module controller

```elixir
plug MishkaAuth.Plug.RequestPlug when action in [:request]

plug(Ueberauth)

alias MishkaAuthPhxWeb.Router.Helpers
```

#### related plugs:
```elixir
MishkaAuth.Plug.LoginedCurrentTokenPlug

MishkaAuth.Plug.LoginedCurrentUserPlug
```


Test links:

```elixir
# http://127.0.0.1:4000/auth/github?strategy=current_user
# http://127.0.0.1:4000/auth/github?strategy=current_token
# http://127.0.0.1:4000/auth/github?strategy=refresh_token

# http://127.0.0.1:4000/auth/google?strategy=current_user
# http://127.0.0.1:4000/auth/google?strategy=current_token
# http://127.0.0.1:4000/auth/google?strategy=refresh_token
```
 

**Calling priority or essential functions in personal projects:**

Login strategies in systems are very different based on user conditions. Also, for convenience, a module called MishkaAuth was created in which some of the functions you need were called, including the function.

```elixir
revoke_token
```

Which allows you to easily customize based on user request or even management request based on your needs. Expire the token and cut off user access if you need to with a custom strategy.

```
[:refresh_token, :access_token, :user_token, :all_token]
```

As you can see in the list above, you can delete tokens based on the requested strategies in your software, or check and delete them all in general. It should be noted that this section has a lot more work to do, especially when multiple tokens are created in each strategy, as well as information such as where the user logs in and the IP and… are temporarily or permanently stored.

 

**Test**

For this project, testing is done in the same way. It is suggested that the project be forked first, and then your Phoenix module be replaced in the project, and then the test be performed. Because a large part of the test is done by Phoenix, which allows us to have a cleaner test. But why aren't the modules edited so there's no need to do so. The only reason is because of time constraints and the low importance of this issue at this time, a package for testing will be uploaded soon, and also in the roadmap of this plugin there is such a thing that after it is done, there is no need to do so.


hex site: https://hex.pm/packages/plug_mishka_auth/
