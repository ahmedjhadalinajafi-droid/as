# Facebook Daily Post Boost — n8n Workflow

This n8n workflow automatically boosts your latest Facebook Page post every day at 9 AM.

---

## How It Works

```
Every day at 9 AM
  → Get your page's latest post
  → Create a Facebook Ad Campaign
  → Create an Ad Set (budget + audience)
  → Create an Ad Creative (links the post)
  → Create the Ad (goes live)
```

---

## What You Need (One-Time Setup)

You need **3 things** from Facebook:

| What | Example | Where to find it |
|------|---------|-----------------|
| Page ID | `123456789` | See Step 1 below |
| Ad Account ID | `987654321` | See Step 2 below |
| Page Access Token | `EAABwzLix...` | See Step 3 below |

---

## Step 1 — Find Your Page ID

1. Go to your Facebook Page
2. Click **About** (left side menu)
3. Scroll down — you will see **Page ID** as a number
4. Copy that number

---

## Step 2 — Find Your Ad Account ID

1. Go to [Facebook Ads Manager](https://www.facebook.com/adsmanager)
2. At the top left you will see your account name and a number like `Act #123456789`
3. Copy **only the numbers** (without `Act #`)

---

## Step 3 — Get Your Page Access Token

1. Go to [Meta for Developers](https://developers.facebook.com/) and log in with your Facebook account
2. Click **My Apps** → **Create App**
3. Choose **Business** type → give it any name (e.g. "My Page Booster") → click **Create**
4. On the next screen, find **Marketing API** and click **Set Up**
5. Go to **Tools** → **Graph API Explorer** (top menu)
6. In the top-right dropdown, select your new app
7. Click **Generate Access Token**
8. Check these permissions:
   - `ads_management`
   - `pages_manage_ads`
   - `pages_read_engagement`
9. Click **Generate Token** and allow the permissions
10. To make the token long-lived (60 days instead of 1 hour):
    - Click **Open in Access Token Tool** (the blue link under the token)
    - Click **Extend Access Token**
    - Then click **Get Page Token** tab and select your Page
    - Copy the **Page Access Token** shown

> Save this token somewhere safe. You will need to repeat this every 60 days.

---

## Step 4 — Import the Workflow into n8n

1. Open your n8n (usually at `http://localhost:5678`)
2. Click **Workflows** in the left menu → **Import from File**
3. Select `facebook-boost-workflow.json` from this folder
4. Click the **Config** node and replace the placeholder values:

| Field | Replace with |
|-------|-------------|
| `REPLACE_WITH_YOUR_PAGE_ID` | Your Page ID (Step 1) |
| `REPLACE_WITH_YOUR_AD_ACCOUNT_ID` | Your Ad Account ID (Step 2) |
| `REPLACE_WITH_YOUR_PAGE_ACCESS_TOKEN` | Your token (Step 3) |
| `DAILY_BUDGET_CENTS` | Budget in cents — `500` = $5.00 |
| `BOOST_DAYS` | Days to run each boost — `1` = 1 day |
| `COUNTRY_CODE` | 2-letter country, e.g. `US`, `AE`, `GB` |
| `AGE_MIN` | Minimum age for audience (default: `18`) |
| `AGE_MAX` | Maximum age for audience (default: `65`) |

5. Click **Save**
6. Toggle the workflow to **Active** (top-right switch)

---

## Schedule

Runs every day at **9:00 AM** (n8n server timezone).

To change the time, edit the cron expression in the **Daily Schedule** node:
- `0 9 * * *` = 9:00 AM
- `0 8 * * *` = 8:00 AM
- `0 12 * * *` = 12:00 PM (noon)

---

## Budget Reference

`DAILY_BUDGET_CENTS` uses the smallest currency unit:

| Value | USD | AED |
|-------|-----|-----|
| `500` | $5.00 | 5 AED |
| `1000` | $10.00 | 10 AED |
| `2000` | $20.00 | 20 AED |

Facebook's minimum daily budget is usually **$1.00**.

---

## Troubleshooting

**"Invalid OAuth access token"** → Token expired. Repeat Step 3.

**"Unsupported post type"** → Only original page posts can be boosted (not shares or reels).

**"Must be approved to create ads"** → Go to Ads Manager and complete account verification.

**No boost but no error** → Open the workflow's **Executions** tab in n8n to see the full log.

---

## Files

| File | Description |
|------|-------------|
| `facebook-boost-workflow.json` | Import this file into n8n |
| `README.md` | This setup guide |
