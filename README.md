# Sales Invoice App

A Flutter (Android) app for creating and managing sales invoices.

## Where things are

| Deliverable | Location |
|---|---|
| SQL scripts | [`backend/sql/`](backend/sql/) |
| REST API source code | [`backend/sql/03_functions.sql`](backend/sql/03_functions.sql). The API is these PostgreSQL functions, exposed by Supabase as `POST /rest/v1/rpc/<function_name>` |
| Screenshots of the database tables | [`docs/screenshots/`](docs/screenshots/) |
| APK | [`release/`](release/) |
| Flutter source code | [`app/`](app/) |

## Run the project

### 1. Create the database

Create a Supabase project, open the **SQL Editor**, and run the scripts from `backend/sql/` in this order:

1. `01_schema.sql`: enums and tables
2. `02_sample_data.sql`: currencies, items with barcodes, and the profile of the test user
3. `03_functions.sql`: the API functions and the triggers that lock approved and cancelled invoices

The last statement of `02_sample_data.sql` creates the profile of the test user, so create that user before running it. In Supabase go to **Authentication → Users → Add user**, enter the email and password from [Test account](#test-account), and tick **Auto Confirm User**.

### 2. Configure the app

```bash
cd app
cp .env.example .env
```

Put these values in `.env`:

```
SUPABASE_URL=https://yopovvmahgnngxtgnixb.supabase.co
SUPABASE_ANON_KEY=sb_publishable_FSAIqJyi3fD8maqJ3B95jw_B6418M6P
```

They point to the author's Supabase project, which already has the database from step 1, so step 1 is only needed if you use your own project.

### 3. Run

```bash
flutter pub get
flutter run
```

Use an Android emulator or a phone.

To install the APK instead, download `release/app-release.apk` to an Android phone and open it. It may ask you to allow installs from this source.

## Test account

Use this account in the app and in the APK. Both are connected to the author's Supabase project:

| | |
|---|---|
| Email | `test-invoiceapp@gmail.com` |
| Password | `test@1234` |

If you set up your own Supabase project, create this same user in step 1 and sign in with it.

## Testing the barcode scanner

Scan the barcodes in the table below. Show them on a computer screen (open this README on GitHub) and use the camera of the phone that runs the app.

1. In the app, tap **New invoice**.
2. Tap **Scan barcode** and allow the camera.
3. Point the camera at one of the barcode images below, about 20 to 30 cm from the screen, until it is inside the green frame.
4. The app shows "Added …" and the item appears on the invoice. Scan another barcode to add another item, or the same one again to increase its quantity.
5. Tap **Done**.

| Scan this | Item added to the invoice | Price (USD) |
|---|---|---|
| <img src="docs/barcodes/5449000000996_cola.png" width="280"><br>`5449000000996` | Cola 330ml | 0.90 |
| <img src="docs/barcodes/4006381333931_marker_pen_set.png" width="280"><br>`4006381333931` | Marker Pen Set (6) | 6.40 |
| <img src="docs/barcodes/8901234567890_notebook_a5.png" width="280"><br>`8901234567890` | Notebook A5 | 3.25 |
| <img src="docs/barcodes/6281006789012_chocolate_bar.png" width="280"><br>`6281006789012` | Chocolate Bar 100g | 1.75 |

A barcode that isn't in the items list shows "No item with barcode …" and nothing is added to the invoice. You can also put an item on the invoice without the camera: tap **Add item** and type its name or barcode. The app does not create items. They come from the database. The images are also in [`docs/barcodes/`](docs/barcodes/).
