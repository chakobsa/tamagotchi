# Deploying the Pet Park web app to a VPS

The app in `webapp/` is a **static site**: HTML, CSS and JavaScript files, with no server code and
no database. Browsers read the pets straight from the blockchain and send transactions through the
students' MetaMask. Your VPS only serves files.

## 1. Point the app at your Pet Park

```bash
./scripts/deploy-park.sh          # once, if you haven't (prints the Pet Park address)
./scripts/webapp-config.sh        # writes webapp/config.js with the network + park address
```

`config.js` is the only file you edit. (URL parameters override it for testing:
`?network=xdc&park=0x…`.)

## 2. Upload

```bash
ssh you@your-vps 'sudo mkdir -p /var/www/petpark && sudo chown $USER /var/www/petpark'
rsync -av --delete webapp/ you@your-vps:/var/www/petpark/
```

Re-run both commands whenever you redeploy the park or change the app.

## 3. Serve it: pick one

### Option A: Caddy (simplest, HTTPS automatic)
```bash
sudo apt install caddy
sudo cp deploy/Caddyfile /etc/caddy/Caddyfile     # then edit the domain on the first line
sudo systemctl reload caddy
```

### Option B: nginx
```bash
sudo cp deploy/nginx.conf /etc/nginx/sites-available/petpark      # edit server_name
sudo cp deploy/petpark-headers.conf /etc/nginx/snippets/petpark-headers.conf
sudo ln -s /etc/nginx/sites-available/petpark /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d petpark.example.com                        # HTTPS
```

Use a domain with HTTPS if you can. MetaMask works on plain http too, but HTTPS avoids browser
warnings and keeps the page from being tampered with on school wifi.

## 4. Check it

- Open `https://your-domain/`: you should see "The Pet Park" and the pets (or "No pets yet").
- Big screen for the projector: `https://your-domain/?screen=1`
- A pet's own page: `https://your-domain/#/pet/0xPetAddress`

## What the app talks to

| | |
|---|---|
| Your VPS | the static files |
| The blockchain RPC | reads (`rpc.xdcrpc.com` by default; all three public XDC RPCs allow browser access) |
| MetaMask (in the student's browser) | signs transactions |
| fonts.googleapis.com | the pixel and text fonts (the app works without them, with system fonts) |

The Content-Security-Policy in `petpark-headers.conf` / `Caddyfile` allows exactly these. If you put a
custom RPC in `config.js`, add its origin to `connect-src`.

Nothing secret is on the server: no keys, no mnemonic. Keep `.workshop/` on your laptop.
