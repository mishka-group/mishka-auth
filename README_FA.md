## - مقدمه
---

یکی از مراحل ضروری در پیاده سازی سیستم ها ساخت یک سیستم سریع و ساده auth می باشد که مطمئن در هر جامعه برنامه نویسی تا موارد خیلی زیادش پیاده سازی شده است. ولی هر کدوم نیاز به کانفیگ مجزا و همینطور ساختار بانک اطلاعات سفارشی و در حقیقت به صورت ساده بخوام بیان کنم از اول نوشتن بخش مورد نظر است.

به همین منظور برای جلوگیری از ساخت هر دفعه بخش لاگین هر پروژه کد های شخصیم رو در قالب یک پکیج با چندین استراتژی از جمله auth2 و همینطور مراحل سفارشی مورد نیاز ُدر یک سیستم رو آماده سازی کردم و کمی بهینه سازی و در مرحله آخر نیز کدباز و منتشر نمودم.

## - هدف
---
هدف از این پروژه آسان سازی مراحل پیاده سازی یک سیستم auth و در آینده نیز سطوح دسترسی برای الیکسیر کارانی هست که می خواهند روی Phoenix کار کنند.

- ساخت مایگریشن دیتابیس با یک تسک
- پیاده سازی کنترلر با چند پلاگ ساده فقط در حد فراخوانی
- پیاده سازی شبکه های اجتماعی برای ثبت نام - بیرون کشیدن اطلاعات بیسیک و لاگین
- پیاده سازی سه استراتژی ( سشن یوزر آیدی - سشن توکن - و ریفرش توکن برای اپ های خارجی)
- پیاده سازی ثبت نام و لاگین مستقیم

از جمله مواردی هست که می شه در این پلاگین ذکر نمود. لازم به ذکر هست این پلاگین با کتابخانه phoenix liveview نیز یک تست کوتاه زده شده و می تونه به صورت سفارشی برای شما کار کنه. 

> باید این نکته را نیز بیان نمود که اگر شما حتی نخواهید از این پلاگین به صورت کامل استفاده کنید باز هم بخاطر کانفیگ چندین پلاگین مهم و پرطرفدار در الیکسیر در ساختار یک پلاگین می تونه یک کمک برای پیاده سازی سیستم شخصی خودتان باشد.

## - نقشه راه

در نسخه اول این پلاگین فقط سعی شد تا حدود زیادی پیاده سازی سیستم در اولیت قرار بگیرد و یک راه مناسبی را باز نمود تا از یک پلاگین تبدیل به یک کامپوننت خوب و جامع برای پیاده سازی یک سیستم سطوح دسترسی و لاگین با اتصال به اسکریپت های معروف و شبکه های اجتماعی تبدیل گردد و پیاده سازی شود.

لذا در آینده تمام تلاش بنده در توسعه این سیستم به عنوان یک سلف پرووایدر می باشد. به همین منظور فناوری های زیادی به این پلاگین ساده اضافه خواهد شد و ممکنه است خیلی از پلاگین هایی که الان استفاده شده به عنوان وابستگی نیز بازنویسی شود.

> یکی از مواردی که در آینده اولیت زیادی خواهد داشت ساخت یک نسخه از پلاگین با حداقل وابستگی خارجی می باشد. به صورت مثال بجای پستگرس از دیتابیس ران تایم ارلنگ و ممکن هست بجای ردیس نیز از otp خود الیکسیر استفاده شود. این مورد خیلی برای تست و همینطور برای افرادی که منابع کمی دارند مهم می باشد و من به شخصه این نیاز را درک کرده و در حال تحقیق و پیاده سازیش هستم.

امکانات ریزی که فعلنه در نسخه بعدی پیاده سازی می شود و همینطور شما فعلنه قادر هستید به صورت دستی خودتان بنویسید که لازم به ذکر هست بازم این پلاگین کمک کننده می باشد به شرح زیر می باشد:

۱. تغییر پسورد
۲. ریست پسورد
۳. لیست کاربران برای ادمین
۴. ساخت پروفایل ذخیره سازی اطلاعات اضافه
۵. لیست توکن های ایجاد شده
۶. پشتیبانی چند توکنی در سیستم
۷. پیاده سازی کپچا ( آزادی در انتخاب بین چندین سیستم)
۸. فعال سازی چند مرحله با ایمیل
۹. فعال سازی چند مرحله ای با پیامک

و موارد دیگر که به مرور به این پست اضافه خواهد شد.

## - آشنایی با پلاگین MishkaAuth
---
لازم به ذکر هست پلاگین در هسته خود با سه استراتژی کلی یعنی 

```elixir
@strategies ["current_token", "current_user", "refresh_token"]
```
کار می کند که دو استراتژی `current_token` و `current_user` برای رندر html می باشد و `refresh_token` نیز برای یک اسکریپت یا یک اپ بیرون وب سایت شما که راه ارتباطی اون نیز به صورت دیفالت `Json‍` می باشد که اگر نیاز به خروجی های دیگری هستید با کمی دست زدن در پلاگین میسر می باشد.

استراتژی هایی که در خود `token` دارند در کل از ردیس استفاده می کنند و همینطور از `jwt` برای رمز نگاری امضای دیجیتالی.  پس یکی از وابستگی های مورد نیاز در سیستم ردیس می باشد که باید روی سرور شما کانفیگ شده باشد و همینطور برای ذخیره سازی اطلاعات کاربر از شبکه های اجتماعی به صورت موقت نیز باز هم ردیس و سر آخر برای ذخیره سازی کاربر و اطلاعات مربوط به هر آیدنتیتی آن نیز در پستگرس که می تواند با تغییر کوچیک در `Ecto` روی دیگر موارد پشتیبانی نیز حساب باز کنید !!

---

بعد از پیاده سازی استراتژی مورد نظر خودتان حال می توانید به دو صورت در وب سایت این سیستم را پیاده کنید. البته باید به این نکته اشاره کرد که هر دو مرحله زیر می تواند به صورت موازی نیز در وب سایت شما فعال باشد نیاز به غیر فعال کردن آن ندارید.

### راه اول: ثبت نام و لاگین از شبکه های اجتماعی
برای تست و بررسی اولیه فعلنه دو شبکه اجتماعی گوگل و گیت هاب برای لاگین و ثبت نام در سیستم به صورت پیشفرض در نظر گرفته شده است. پس در آینده به تعداد این شبکه ها اضافه خواهد شد و شما فقط کافی است که `token` های این شبکه های اجتماعی را از وب سایت های خودشان بگیرید و تو کانفیگ قرار بدهید همین و دیگر نیازی به کار دیگری نیست.

### راه دوم: ثبت نام و لاگین با فرم در وب سایت یا Json Api در کنترلر
اگر نمی خواهید از شبکه های اجتماعی استفاده کنید یا می خواهید قدرت انتخاب بیشتری به کاربر بدهید باز هم فقط کافی هست یک فرم ساده **html** بسازید و تمام بقیه کار ها فقط فراخوانی یک فانکشن می باشد.

> به علت استفاده از توکن در بیشتر سیستم برای حذف کلی یا به تفکیک بر اساس استراتژی های مورد نظر خودتان چند فانکشن ساده نیز درست گردیده است که در ادامه برای شما معرفی خواهد شد


## - نصب و پیاده سازی کانفیگ مورد نیاز

#### ۱- ساخت یک پروژه جدید

اولین مرحله ساخت یک پروژه جدید می باشد و اگر پروژه ای از قبل دارید که نیازی به ساخت آن نیست ولی باید کاربران خودتان را به سیستم جدید با چند دستور ساده الیکسیر انتقال بدهید یا سعی کنید به صورت تلفیقی با هر دو سیستم یعنی سیستم شخصی و این سیستم کار کنید.

```elixir
mix phx.new your_project
```

---

#### ۲- معرفی این پلاگین در mix فایل پروژه خودتان

در این مرحله فقط کافی هست در فایل `mix` در فانکشن `deps` این پلاگین یعنی `MishkaAuth` را اضافه کنید به صورت زیر

```elixir
defp deps do
  [
    ....
    {:mishka_auth, "~> 0.0.1", hex: :plug_mishka_auth}
    ....
  ]
end
```

بعد کامند `mix deps.get` رو بزنید و تمام. حال پلاگین و تمام وابستگی های مربوط به خودش را دانلود کرده و روی پروژه شما. حال نوبت این است که شما کانفیگ مربوط به این پلاگین را در پروژه خودتان در مرحله بعدی اضافه کنید

---

#### ۳- اضافه کردن کانفیگ مربوط به پلاگین.

در شروع این بخش باید خدمت عزیزان این نکته را بیان کنم که کانفیگ های وارده و مورد نیاز برای چند پلاگین استفاده شده در MishkaAuth می باشد. که تلاش من در این هست که در آینده این موارد را یکپارچه سازی کنم ولی فعلنه در چندین نسخه آینده فقط قرار است در زمینه امکانات و حل مشکل مشغول به فعالیت باشم. ولی در کل بسیار ساده می باشد

فقط کافیست فایل `config.exs` را باز کنید و یک خط بالای خط `import_config "#{Mix.env()}.exs"` دستورات زیر را اضافه کنید.

در مرحله اول شبکه های اجتماعی که می خواهید را کانفیگ کنید به صورت مثال برای گیت هاب و گوگل به صورت زیر می باشد

```elixir
config :ueberauth, Ueberauth,
base_path: "/auth",
providers: [
  github: {Ueberauth.Strategy.Github, [default_scope: "read:user", send_redirect_uri: false]},
  google: {Ueberauth.Strategy.Google, [default_scope: "https://www.googleapis.com/auth/userinfo.email https://www.googleapis.com/auth/userinfo.profile"]},
]
```
در موارد بالا بر اساس دسترسی مورد نیاز از این دو سایت مذکور اطلاعات پایه را استراخ می کنیم البته بعد از تایید کاربر

و در مرحله بعدی برگشت به سایت و اطلاعات مربوط به api خود را قرار می دهید از جمله کلید خصوصی و شناسه که بر اساس هر شبکه اجتماعی این مورد متفاوت می باشد فقط کافی است سرچ کنید در سایت خودشان و به راحتی اطلاعات مربوطه را بگیرید به عنوان مثال باید برای گوگل به قسمت گوگل دولپر کنسول بروید.

```elixir
config :ueberauth, Ueberauth.Strategy.Github.OAuth,
client_id: "CLIENT_ID",
client_secret: "SECRET_KEY",

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
client_id: "CLIENT_ID",
client_secret: "SECRET_KEY",
redirect_uri: "http://YOUR_DOMAIN_URL/auth/google/callbacktest"
```


در مرحله بعد شما فقط کافی هست که نوع رمز و همینطور اندازه اون بر اساس منابع سرور و همینطور نیازمندی خودتان مشخض کنید

```
config :mishka_auth, MishkaAuth.Guardian,
issuer: "mishka_auth",
allowed_algos: ["ES512"],
secret_key: %{Your secret Key}
```

به عنوان مثال من ES512 را انتخاب کردم که واقعا نیاز نیست و شما می تونید کمتر از اون رو استفاده کنید برای ساخت کلید خصوصی برای jwt می تونید این آموزش در انجمن رو ببنید که فقط کافیه این کامند رو ببنید

```elixir
JOSE.JWS.generate_key(%{"alg" => "ES512"}) |> JOSE.JWK.to_map |> elem(1)
```

لینک: https://devheroes.club/t/guardian/1584

خروجی بالا رو می تونید بجای Your secret Key بزارید . و در آخر هم کانفیگ های زیر رو در ادامه قرار بدهید

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

کانفیگ بالا خیلی ساده می باشد بیشتر دست شما را باز می کند تا هر صفحه ای که می خواهید ریدایرکت کنید یا هر repo که می خواهید را مشخص کنید و همینطور از ماژول PubSub مخصوص به خودتان در آینده ناتفیکیشن بگیرید و همینطور پسورد ردیس فایل خود را قرار بدهید.

#### از بالا به ترتیب به شرح زیر می باشد:

۱. ماژول ریپو که در پروژه شما استفاده شده است
۲. بعد از لاگین به کجا ریدایرکت شود
۳. بعد از خطا کجا ریدایرکت شود 
۴ - پیام مربوط به ثبت نام موفقیت آمیز به همراه لاگین
۵. جدول ردیس مربوط به استراتژی کارنت توکن ( نیاز به تغییر نیست ولی بر اساس تصمیم شما تغییر می کند)
۶. اسم جدول ریفرش توکن مثل گزینه ۵
۷. زمان انقضای توکن ریفرش توکن
۸. زمان انقضای اکسز توکن
۹. زمان انقضای کارنت توکن
۱۰. اسم جدول موقت نگهداری اطلاعات موقت
۱۱. پسورد ردیس
۱۲. ماژول view که بعد از ارور در ذخیره سازی اطلاعات باید ریدایرکت شود
۱۳. مثل گزینه ۱۲ حال اسم فایل html مورد نظر
۱۴.  ذخیره سازی خودکار بعد از لاگین از شبکه اجتماعی یا نمایش اطلاعات در فرم و اجازه به کاربر برای ویرایش 
۱۵. معرفی ماژول pub_sub ( در آینده استفاده می شود ولی معرفی بفرمایید)

---

> ۹۰ درصد کل کار هایی که باید انجام می شد تمام شد.

#### ۴- ساخت دیتابیس 

فقط کافیست در کنسول خود در مسیر پروژه کامند زیر را بزنید

```elixir
mix mishka_auth.db.gen.migration
```
بعد از کامند بالا بدون مشکل اجرا شد حال می توانید به راحتی دستور زیر را بزنید و تمام

```elixir
mix ecto.migrate
```

----

#### ۵- پیاده سازی روتر و کنترلر

این بخش موارد اضافه هست که دیگر بر اساس نیاز شما انجام می شود ولی چند فانکشن دیفالت دارد که هر صورت شما می خواهید می تواند قرار بگیرید البته لازم به ذکر هست پلاگین گاردین از اوبرآص یکمی برای ما متاسفانه محدودیت درست کرده مخصوصا اینکه اصلا api رو پشتیبانی نمی کرد و بنده دورش زدم و دلیل استفاده از این پلاگین این بود که خیلی وقت هست دارد توسعه داده می شود و بسیار پرطرفدار می باشد ولی در صورت اذیت کردن در آینده حتما بازنویسی کامل در پروژه می شود ولی در تست های بنده هیچ مشکلی نبود و بسیار دلپذیر انجام وظیفه می کند


فرض بر این بگیریم که فرم لاگین و ثبت نام ما در فانکشن اکشن index می باشد فقط کافیست اینو بنویسید که اصلا ربطی به پلاگین میشکا ندارد بلکه مربوط به Ecto و ذخیره در دیتابیس می باشد

```
  def index(conn, _params) do
    changeset = MishkaAuth.Client.Users.ClientUserSchema.changeset(%MishkaAuth.Client.Users.ClientUserSchema{}, %{})
    render(conn, "index.html", changeset: changeset)
  end
```

فرض  بر اینکه در صفحه بالا می خواهید ثبت نام به جایی پست شود یا می خواهید api به یک فانکشن اطلاعات برود و ثبت نام انجام گردد فقط کافیست این فانکشن قرار بدهید اسمش هرچی می خواهید بزارید مهم نیست مثل موارد بالا


```elixir
  def register(conn, %{"client_user_schema" => client_user_schema}) do
    MishkaAuth.Helper.HandleDirectRequest.register(conn, client_user_schema, :normal, :html)
  end
```


همانطور که در اول همین مطلب گفتم ما دو روش داریم یکی مستقیم و یکی هم از شبکه های اجتماعی . موارد بالا همه آن ها مستقیم می باشد 

حال نوبت به لاگین مستقیم می رسد که بر اساس یوزر نیم پسورد یا ایمیل پسورد می باشد که دو فانکشن آن را به شرح زیر می باشد:

```elixir
  def login(conn, %{"password" => password, "email" => email}) do
    MishkaAuth.login_with_email(:current_token, conn, email, password)
  end


  def login(conn, %{"password" => password, "username" => username}) do
    MishkaAuth.login_with_username(:current_user, conn, username, password)
  end
```

> نکته: حتما در بالای کنترلر خود این `alias MishkaAuthPhxWeb.Router.Helpers` را قرار بدهید و اگر می خواهید می توانید از گارد برای هر فانکشن استفاده کنید به عنوان مثال بنده استراتژی هایی که می خواستم را در یک متغیر گلوبال قرار دادم به صورت ` @strategies ["current_token", "current_user", "refresh_token"]`


-----

حال نوبت به چند فانکشن پیشفرض گاردین می رسد برای لاگین شدن و یا ثبت نام از شبکه های اجتماعی 

```
  def request(conn, %{"strategy" => strategy, "provider" => _provider}) when strategy in @strategies do
    render(conn, "request.html", callback_url: MishkaAuth.callback_url(conn))
  end
```
شما می توانید از when استفاده نکنید دوستان و یا موارد دیگر فقط برای نمایش اینکه فانکشن شما را مجبور نمی کند قرار داده شد


## توجه توجه توجه

 این یک فانکشن با اسم کاستوم می باشد فانکشنی که شما بعد از شبکه اجتماعی به آن برگشت می کنید پس اسم ان قابل تغییر است و شما باید اسم این روتر متصل به این فانکشن را بدهید

```elixir
  def callbacktest(conn, %{"code" => code, "provider" => provider}) do
    MishkaAuth.handle_callback(conn, Helpers, :auth_path, code, provider)
  end
````

در حقیقت این فانکشن به شما کمک می کند تا استراتژی مورد نظر خود را به کال بک ها بدهید و خروجی دلخواه خود را بگیرید

در آخر فانکشن کال بک که به صورت کثیف نوشتمش اینجا و شما می توتنید در چندین فانکشن مختلف از اون استفاده کنید و یا گارد بزارید برای فانکشن یا هرکار دیگه فقط خواستم نمایش بهتری بدهم که اول فهمیده بشود

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

اولین فانکشن برای خطا و دومی اگر اوکی بود به مراحل بعد می رود . حال فقط کافیست روتر ها را اضافه کنیم و تمام


برای صفحه فرم که خودتان می دانید چطور روتر بسازید ولی می تونه مثلا به این صورت باشه

```elixir
  scope "/", MishkaAuthPhxWeb do
    pipe_through :browser

    get "/", AuthController, :index
  end
```

مسیر "/" یک صفحه مثلا فرم لاگین که می تونه هر آدرسی بگیره و سفارشی شماست  و در آخر روتر مربوط به فانکشن های بالا که معرفی کردیم

```
  scope "/auth", MishkaAuthPhxWeb do
    pipe_through :browser
    post("/login", AuthController, :login)
    post("/register", AuthController, :register)


    get("/:provider", AuthController, :request)
    get("/:provider/callbacktest", AuthController, :callbacktest)

    get("/:provider/callback", AuthController, :callback)
  end
```


از روتر های بالا ( login و register و callbacktest) قابل تغییر هست به هر اسم و مسیری که می خواهید ولی دو مورد بعدی خیر

#### ۶- دیگه وقت استراحت است

کار به صورت کامل تمام شده و دیگر نیازی به چیزی ندارید و سیستم پیاده سازی شده است. اگر می خواهید راحتر باشید برای فورس کردن کاربر به ورود به وب سایت ما چند پلاگ نیز برای روتر آماده کردیم که اگر خیلی خسته بودید و حالشو نداشتید در کنترلر هم می تونید استفاده کنید.

قبل از معرفی پلاگ های مذکور لطفا در بالای کنترلر خودتان این سه خط را قرار بدهید زیر ماژول کنترلر

```
  plug MishkaAuth.Plug.RequestPlug when action in [:request]
  plug(Ueberauth)
  alias MishkaAuthPhxWeb.Router.Helpers
```

#### پلاگ های مربوطه:

```elixir
MishkaAuth.Plug.LoginedCurrentTokenPlug
MishkaAuth.Plug.LoginedCurrentUserPlug
```


#### لینک های تست:

```elixir
# http://127.0.0.1:4000/auth/github?strategy=current_user
# http://127.0.0.1:4000/auth/github?strategy=current_token
# http://127.0.0.1:4000/auth/github?strategy=refresh_token


# http://127.0.0.1:4000/auth/google?strategy=current_user
# http://127.0.0.1:4000/auth/google?strategy=current_token
# http://127.0.0.1:4000/auth/google?strategy=refresh_token
```
---

### فراخوانی توابع اولویت دار یا ضروری در پروژه های شخصی:

استراتژی های لاگین در سیستم ها بر اساس شرایط کاربران بسیار متفاوت می باشد به همین ترتیب برای راحتی کار یک ماژول به نام MishkaAuth ساخته شد که در آن برخی از توابع مورد نیاز شما فراخوانی شد از جمله تابع 

```elixir
revoke_token
```

که این امکان را به شما می دهد تا به راحتی بر اساس درخواست کاربر یا حتی درخواست مدیریت بر اساس نیازی که دارید. توکن را منقضی کرده و اگر نیاز داشتید با یک استراتژی سفارشی از طرف خودتان دسترسی کاربرا را قطع کنید 

```elixir
[:refresh_token, :access_token, :user_token, :all_token]
```
همانطور که در لیست بالا می بنید شما امکان این را دارید که توکن ها را بر اساس استراتژی های درخواستی در نرم افزارتان حذف کنید و یا اینکه به صورت کلی همه را بررسی نموده و حذف کنید. لازم به ذکر هست این بخش خیلی جای کار بیشتری دارد مخصوصا در زمانی که چندین توکن در هر استراتژی ساخته شود و همینطور اطلاعاتی از جمله مکان لاگین شدن کاربر و آیپی و ... نیز به صورت موقت یا همیشگی ذخیره سازی گردد.

---
---

> امکانات زیر از نسخه 0.0.2 اضافه شده است لطفا فایل config خودتان را بر اساس آخرین به روز رسانی تغییر دهید

### سنتایزر و ولیدیشن برای ورودی و خروجی با امکان کاستوم

یکی از مواردی که می تونه کنترل بهتری برای مدیریت دیتابیس و تا حدودی در زمینه امنیت بده. کنترل ورودی ها و خروجی ها فیلد های پر شده به وسیله کاربر می باشد 

ماژول مربوطه:
```
MishkaAuth.Helper.SanitizeStrategy
```
در این ماژول یک فانکشن main وجود دارد به نام `changeset_input_validation(changeset, :custom` این فانکشن چک می کند که آیا شما در فایل کانفیگ ولیدیشن دیفالت را می خواهید که تشکیل شده از سه رجکس می باشد 

```elixir
  def regex_validation(:email) do
    ~r/^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$/
  end

  # Must contain lowercase and uppercase and number, at least 8 character.
  def regex_validation(:password) do
    ~r/(?=.*\d)(?=.*[a-zA-Z])(?!.*(\s)).{8,32}$/
  end

  # No capital letter allowed, can contain `_` and `.`, can't start with number or `_` or `.`, can't end with `_` or `.`.
  def regex_validation(:username) do
    ~r/(?!(\.))(?!(\_))([a-z0-9_\.]{2,15})[a-z0-9]$/
  end

```

به صورت پیشفرض شما نیازی به دست زدن یا فراخوانی ندارید اگر فقط می خواهید جدا از این موارد کار کنید و در حقیقت `changeset`  خودتان را صدا بزنید فقط کافیست دو پارامتر کانفیگ زیر را ارزش گذاری نمایید. اولین مورد ماژول و دومین مورد اسم فانکشن که به صورت `atom` باید نوشته شود.

```
input_validation_module
input_validation_function
```

> نکته: یک پارامتر دیگردر کانفیگ باید قرار بگیرد که ارزش آن به صورت بولین می باشد تا اینکه از شما اجازه بگیرد آیا نیاز به ولیدیشن کاستوم دارید یا خیر `input_validation_status`


### query های اضافه برای فایل `client_user_query.ex`

برای راحتی کار شما فقط کافیست فانکشن های زیر را فراخوانی کنید

`show_users` برای نمایش کاربران در پنل ادمین خودتان که بر اساس `status` تعداد رکورد در هر صفحه و صفحه ای که می خواهید لود شود ورودی می پذیرد

`reset_password` در موقع فراموشی پسورد و ریست شدن اون به واسطه ایمیل و همینطور ورفای کد و تغییر ئسورد

`verify_email` برای فعال سازی اکانت هایی که ایمیل خودشون رو فعال نکردن که شامل ایجاد کد رندوم و ارسالش و همینطور وریفای کد برای فعال سازی ایمیل

`delete_password` در مواقعی که کاربر یک بار ثبت نام کرده به صورت دایرکت یا پسورد قرار داده و الان فقط می خواد از شبکه اجتماعی استفاده کنه و نیازی به پسورد نداره

`add_password` در زمانی که کاربر با شبکه اجتماعی ثبت نام کرده است و حال دوست دارد برای حساب کاربری خودش پسورد جدید قرار بدهد.

> لازم به ذکر است برای تمامی مواردی که ایمیل ارسال می شود شما نیاز دارید اول افزونه `bamboo` رو کانفیگ کنید روی پروژه خودتون و در کانفیگ معرفی کنید به افزونه `MishkaAuth` بعد همینطور قالب ایمیل مخصوص به خودتون رو نیز در یک فایل الیکسیر بسازید و معرفی نمایید

داکیومنت پلاگین ایمیل: https://github.com/thoughtbot/bamboo

فقط کافیه یک فایل بسازید در یک مسیری و این خطوط رو بزارید توش:

```elixir
# some/path/within/your/app/mailer.ex
defmodule MyApp.Mailer do
  use Bamboo.Mailer, otp_app: :my_app
end
```
و به وسیله لینک بالا راه ارسال ایمیل رو نصب و همینطور کانفیگ کنید روی این پلاگین `smtp` استفاده شده. بعد از ساخت فایل بالا در کانفیگ در پارامتر `mailer` اسم کامل ماژول را قرار بدهید.

### تخصیص قالب اختصاصی ایمیل:

```
reset_password_email
verify_email
```

در دو پارامتر بالا شما می توانید فانکشن و ماژول را معرفی کنید که یک ورودی دارد که تمامی اطلاعات در آن قابل چاپ و همینطور امکان جایگزاری در قالب اختصاصی هست

#### نمونه کانفیگ: 

```
reset_password_expiration: 300, #5min
verify_email_expiration: 300, #5min
reset_password_email: %{module: MishkaAuth.TestBodyEmail, function: :reset_password_email_body},
verify_email: %{module: MishkaAuth.TestBodyEmail, function: :reset_password_email_body},
```

> منقضی شدن کد رندوم برای ورفای در ردیس نیز در بالا قابل تغییر می باشد.

#### نمونه ساخت یک ماژول:

```elixir
defmodule MishkaAuth.TestBodyEmail do

  @site_link MishkaAuth.get_config_info(:site_link)

  def reset_password_email_body(info) do
    %{
      text: "کد تغییر  و فراموشی پسورد  #{@site_link}/reset-password/#{info.code}",
      html: "کد تغییر  و فراموشی پسورد  #{@site_link}/reset-password/#{info.code}",
    }

  end

  def verify_email_body(info) do
    %{
      text: "کد تغییر  و فراموشی پسورد  #{@site_link}/reset-password/#{info.code}",
      html: "کد تغییر  و فراموشی پسورد  #{@site_link}/reset-password/#{info.code}",
    }
  end
end
```

> در مثال بالا ما از `html`  استفاده نکردیم ولی شما می توانید از این مورد استفاده کامل رو ببرید و موارد درخواستی خودتون رو پیاده کنید


### لیمیتر

مطمئنن این بخش بیشتر جنبه حمایتی داره و کداش تا حدودی بر اساس نیاز بنده ثابت نوشته شده است. و اگر شما نیاز اختصاصی دارید باید این موضوع رو به شما بگم که فعلا برنامه ای برای داینامیک سازیش ندارم. ولی خیلی کمک کننده هست و هزینه اسپم کردن روی رودتر های درخواستی شما رو می گیره و مچ می شه با کد کپچای گوگل.

ماژول: `MishkaAuth.Client.Users.ClientUserLimiter`


فانکشن اصلی:

```elixir
  def is_data_limited?(strategy, email, user_ip) do
    case MishkaAuth.get_config_info(:limiter) do
      true ->
        limiter(strategy, email, user_ip)
      _ ->
        {:error, :limiter, :inactive}
    end

  end
```
همانطور از کد بالا متوجه شده اید. شما نیاز دارید در کانفیگ پارامتر `limiter` رو قرار بدید و ارزش بولین بهش بدید

استراتژی هایی که فعلنه اماده شده:
```
  # strategies = %{
  #   :register_limiter,
  #   :login_limiter,
  #   :reset_password_limiter,
  #   :verify_email_limiter
  # }

```

در ورودی های مربوط به این فایل همیشه سه ورودی باید فراخوانی شود که به شرح زیر می باشد:

`strategy, email, user_ip`

بجز استراتژی ثبت نام که بر اساس `user_ip` چک می شه بقیه چون در دیتابیس وب سایت موجود هست با `email` کاربر بررسی می شه

در فایل زیر می تونید مراحل مسدود سازی رو ببنید

https://github.com/mishka-group/mishka-auth/blob/master/lib/client/users/client_user_limiter.ex


### پیاده سازی کد کپچا

کد کپچا فعلنه فقط گوگل رو پشتیبانی می کنه و در آینده ممکنه به اون اضافه بشه. البته اگر نظری در این رابطه دارید حتما با ما به اشتراک قرار بدهید

برای فراخوانی اون فقط کافیه ماژول `MishkaAuth.Helper.Captcha` رو صدا بزنید به همراه فانکشن `verify(:google, google_params)`  لازم به ذکر هست که حتما باید در کانفیگ نیز پارامتر های `captcha` و `google_re_captcha_secret`  قرار گرفته باشد.


نگاه اجمالی به کانفیگ های مورد نیاز:

```elixir
config :mishka_auth, MishkaAuth,
repo: YOURREPO.Repo,
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
redix: "REDIS PASSWORD",
changeset_redirect_view: MishkaAuthWeb.AuthView,
changeset_redirect_html: "index.html",
register_data_view: MishkaAuthWeb.AuthView,
register_data_html: "index.html",
automatic_registration: true,
pub_sub: MishkaAuth.PubSub,
input_validation_status: :default,
input_validation_module: nil,
input_validation_function: nil,
captcha: {true, :google},
google_re_captcha_secret: "RECAPTCHA SECRET",
site_link: "YOUR SITE LINK",
limiter: true,
reset_password_expiration: 300, #5min
verify_email_expiration: 300, #5min
reset_password_email: %{module: MishkaAuth.TestBodyEmail, function: :reset_password_email_body},
verify_email: %{module: MishkaAuth.TestBodyEmail, function: :reset_password_email_body},
email_name: "@trangell.com",
mailer: MishkaAuth.Email.Mailer
```

نمونه کانفیگ مربوط به ایمیل:

```elixir
config :mishka_auth, MishkaAuth.Email.Mailer,
adapter: Bamboo.SMTPAdapter,
  server: "YOR MAIL SERVER",
  hostname: "YOUR HOST NAME",
  port: 587,
  username: "YOUR EMAIL OR USERNAME",
  password: "YOUR PASSWORD",
  tls: :if_available,
  allowed_tls_versions: [:tlsv1, :"tlsv1.1", :"tlsv1.2"],
  retries: 1,
  no_mx_lookups: true,
  auth: :always

```
---
---

### تست

برای این پروژه تست نویسی انجام شده به همین ترتیب پیشنهاد می شود اول پروژه فورک شود و بعد ماژول فونیکس شما در پروژه جایگزین گردد بعد تست انجام شود . چون بخش بزرگی از تست به واسطه فونیکس انجام می گیرد و این امکان را می دهد که تست تمیز تری داشته باشیم. اما چرا ماژول ها اد نشده تا نیاز به این کار نباشد . تنها دلیلش بخاطر کبود وقت بوده و اهمیت کم این موضوع در این زمان فعلی به زودی یک پکیج برای تست نیز اپلود می گردد و همینطور در نقشه راه این پلاگین چنین موردی قرار دارد که بعد از انجام شدنش دیگر نیازی به چنین کاری نیست.

----

### لینک های مربوط به این پلاگین

* لینک گیت هاب: https://github.com/mishka-group/mishka-auth

* لینک پلاگین از پکیج منیجر هکس: https://hex.pm/packages/plug_mishka_auth/

* لینک readme فارسی: https://github.com/shahryarjb/mishka-auth/blob/master/README_FA.md

* لینک readme انگلیسی: https://github.com/mishka-group/mishka-auth/blob/master/README.md
