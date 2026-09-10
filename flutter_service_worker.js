'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/AUTO_MERGE": "057dcd2b0978da33b2287ecdbd5ccf38",
".git/COMMIT_EDITMSG": "fd0df72c1aa4221184cb5b30e9d4dda7",
".git/config": "68c62e19c845a558098d51ca700d49a6",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/FETCH_HEAD": "82a81ce3b9ab379a6bf650f87615cc1a",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "966418ed7b87b4036da40a18016412b0",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "6794e3fe37cf51703487735edf47ab5a",
".git/logs/refs/heads/gh-pages": "2124f9db9fc712dedf9de6c6e926c6a1",
".git/logs/refs/remotes/origin/gh-pages": "40c45f650d497814f5ecc51b20c1a35a",
".git/objects/02/1d4f3579879a4ac147edbbd8ac2d91e2bc7323": "9e9721befbee4797263ad5370cd904ff",
".git/objects/05/64c561fe574582a5cdd3a1fcda58d421faf065": "88ada2ae9a2c818b27a97569c501ff0c",
".git/objects/09/ef34f4c29cc57e768130cee7ab4e3683df34ff": "ccf8813c01654d44c74cfb175f00dcee",
".git/objects/0a/c87df58cadd1014e76f6d4366450bc61efe8dd": "ea60d3f348918357b7949d7cfbd76057",
".git/objects/0d/48a222ac56bfaee0e7439115b0f2b72692454f": "163a072253ced8f75e442221362c5382",
".git/objects/0d/f2168ada5971ee6c3c4440f8c32019818eeba0": "bda70cfc5df96e197b0c35743a00f341",
".git/objects/12/7115692633326a02ceae638b8b8e8681dc8284": "363d2049ac8ddd0cbdc9fce0b2af9bc0",
".git/objects/14/a3e59e0c4843c48016320cad26d918fc5a8dfa": "8c992c903d8e00d738e49d4aa34c5e93",
".git/objects/16/bda0a8f23702c8ccbde75c38e25c3836940df5": "ca22a13c4df7b5c23b1245a5e3883205",
".git/objects/18/e5e0aec0bc99ffb223bf134561dbebd33347eb": "4feb40946b2f0f6e119ea534f4b7da83",
".git/objects/19/db0ea0b4c43340ebb67f908d2def78f478344a": "42e9c54a263ae0f8fb806dbf6c7ed157",
".git/objects/1a/40f33da5e9f0c07f4f17dd0aeadfc0f24787fd": "bb42decb833ebac89c50878412a22822",
".git/objects/1c/f25d2ef2c4d214b5d5efb14a8b0dfbb2279b8f": "23067dfeaa7647db8809971fd3ad0cc8",
".git/objects/20/3a3ff5cc524ede7e585dff54454bd63a1b0f36": "4b23a88a964550066839c18c1b5c461e",
".git/objects/29/f22f56f0c9903bf90b2a78ef505b36d89a9725": "e85914d97d264694217ae7558d414e81",
".git/objects/2c/ba0f101023198a2004f9922da03c7a6f2348e7": "39e24c0a7068d4c777663db6133cbb93",
".git/objects/2d/711b5b7a27fd5e5bb5479f6404eb10e6595d76": "5e6b1ee269baa6aa35f2ff315583dfea",
".git/objects/33/a48aeaec2053c54ae6867c20b31e95cc2d5cbc": "8a9fab8864ed6ed3ec603f7bb28ebdf6",
".git/objects/37/fabeb232fa4c8dc0345fb1f6abfa2cfeabdf27": "24d8b3a751d344ca2163af78d523b44e",
".git/objects/3a/1d346a33edde24c29e1ce2affa8404c8c5c682": "924315c0de1f00b0a67c8c7e40102c01",
".git/objects/3a/3b06b4772a72483645e44b2e28f55cead35895": "8487996d8f116902191d5549088f74f3",
".git/objects/3b/d6e8e22dd3f69bfbfcb64e19eff92e24994f1a": "73bc57a628e9eadfd76302ad5c2bf407",
".git/objects/41/ff60a3501db03fcc2827dd7eccf7ec114a2d0d": "be64c7b3e66f91ce59f56fbc3bb162ae",
".git/objects/42/9af29e40d53da414f58407c86e67f041793c03": "0edc6d39a65b4620bdb5f58f7df7821a",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/4b/f395ba3a78622b057647758a1b838c06396100": "5de7b9a2409f9803c2c6288255cf274b",
".git/objects/4d/bf9da7bcce5387354fe394985b98ebae39df43": "534c022f4a0845274cbd61ff6c9c9c33",
".git/objects/4f/fbe6ec4693664cb4ff395edf3d949bd4607391": "2beb9ca6c799e0ff64e0ad79f9e55e69",
".git/objects/51/ab65ff651bbd06b045846a9fdb22b1033ebd8e": "c639e33a8a1a3491963ee4a68b95e5a7",
".git/objects/56/46c0607385c5c31394048a3f0f3a2ff0d95d6d": "95ed0215b902335886c027d6c1384525",
".git/objects/58/007ff26b1f41648b9710d972ac46302077b9ac": "93e9b28af7ddfa3ffb5bf236a395d9f6",
".git/objects/5a/54e369c7559364470673af21f69ccc1733ba2f": "39f7db4aae5b33a8b93800949fb7d724",
".git/objects/5c/52fff9056d31b6d08bbc66f2bcc01741ce73a8": "1db1d5647d6470840b0e6107e3272edc",
".git/objects/5e/5d688dc1146088ca7d924e59643118ef738ca4": "fe9d77dfad23632f44be15d240222f67",
".git/objects/5e/d43e0563e755bf4290f63e0e823db9e2a641de": "540df6edacf3f8cccbeb97d3aa12b01d",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/6f/60a220053f2b27d6a047c3a2599e33c4040a4b": "ecaf21cdce160daca0b133ad0e82f4f8",
".git/objects/78/d0d086eb4cd83aa0fb60571f5bc10cb57af989": "5db5724020433b1b60fc7dc375b47401",
".git/objects/7a/6c1911dddaea52e2dbffc15e45e428ec9a9915": "f1dee6885dc6f71f357a8e825bda0286",
".git/objects/80/57ea905f1055b2cb1f997946c8906fd1dcff3b": "0d67e087fa87910dbc742887ab7e6f57",
".git/objects/88/cfd48dff1169879ba46840804b412fe02fefd6": "e42aaae6a4cbfbc9f6326f1fa9e3380c",
".git/objects/8a/aa46ac1ae21512746f852a42ba87e4165dfdd1": "1d8820d345e38b30de033aa4b5a23e7b",
".git/objects/8c/54458bb825f966e4e69d9a445e6b7ab8f9394e": "074203edfff0fe47e82ad8bb5a5f6c2c",
".git/objects/91/cc8bbe0d4fc0f76a40f13f96c567210d3d7c1d": "45c76036c813d101a61f1116bef11a13",
".git/objects/93/8daac30f52ea88ee432885eb6c8c5b4ed171cd": "5349e09ea23c5a57ba2b8426c6f9cbea",
".git/objects/98/0d49437042d93ffa850a60d02cef584a35a85c": "8e18e4c1b6c83800103ff097cc222444",
".git/objects/9b/3ef5f169177a64f91eafe11e52b58c60db3df2": "91d370e4f73d42e0a622f3e44af9e7b1",
".git/objects/9b/eea364c89a0466162f155f9143703eeb447068": "d79e5f970facd9f01275de39425e73aa",
".git/objects/9e/3b4630b3b8461ff43c272714e00bb47942263e": "accf36d08c0545fa02199021e5902d52",
".git/objects/a1/1c19c09c87db807c29ce98c88117b69c0b71cd": "c907509709b723d1f0b3db0818ddeba3",
".git/objects/a7/a457f11af61fc08997040c02e9f978842d9d19": "5e802f3005a9ef35a309ef1f5f1186e2",
".git/objects/ae/33b7fbc54b7a5b7f34f3a521acc97da5684bfd": "b9e972dd21a8ea175c4cc61776b9c448",
".git/objects/b2/4783170f71a1b5bb6b7dc7a607b96377aef7c3": "4d133025246493193500da26be6ececd",
".git/objects/b3/444fbe991f39f1bd4bda0ded759543870b851e": "8828aca20391a1eabc700aa3fe801548",
".git/objects/b4/0de785d61a35d12b56c35804aaa696fccf89e7": "e2e9d936e8bc69dbf8926cb4689952fd",
".git/objects/b6/b8806f5f9d33389d53c2868e6ea1aca7445229": "b14016efdbcda10804235f3a45562bbf",
".git/objects/b7/49bfef07473333cf1dd31e9eed89862a5d52aa": "36b4020dca303986cad10924774fb5dc",
".git/objects/b7/72fe4da3e58ed09be57a281daae67a04d2610f": "c58ad60b18d104e0be07b4db23f8165b",
".git/objects/b9/2a0d854da9a8f73216c4a0ef07a0f0a44e4373": "f62d1eb7f51165e2a6d2ef1921f976f3",
".git/objects/b9/d51df2f26d80938a1a049aeefe1cd551880a9b": "e16dcd7512362f74e4c0b4c301bb4e3d",
".git/objects/bc/7431a5db18c5634633957c293da99b96ee0991": "71a2d5fec676c28036ab272aea2ee842",
".git/objects/c4/016f7d68c0d70816a0c784867168ffa8f419e1": "fdf8b8a8484741e7a3a558ed9d22f21d",
".git/objects/ca/3bba02c77c467ef18cffe2d4c857e003ad6d5d": "316e3d817e75cf7b1fd9b0226c088a43",
".git/objects/ce/625a4e4097e935a05f6dcc275df7fed73ed570": "dfe34a7b6c5f4472eb85813b28671603",
".git/objects/cf/384b90ff150480c1533005bd448da741a797b6": "11759e0f56f1dd93ce3f9c01c355e039",
".git/objects/d2/48d1984275b53aa450dbf48468462e28b26c91": "523997e5150e2139971d8e84f6b384ee",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d4/cdc79bceff16c7c949beeba08f2fb103df70f4": "fc4f745333e9c6cb86cdb07932d3d0d7",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/d8/27597a81842fefdc67edab756588391262c3da": "4ef1090a09218eb54c20e940b195065c",
".git/objects/d8/741b32c2470a58d580bd0e5f9e5a9fb9bdb27e": "f958bbe980d56342d7e8767fed293483",
".git/objects/d9/cad8de53dff0b2d4191a1a2ea2f4114fdaf873": "45a9f7a2fd60529470b441bdbdc2999e",
".git/objects/db/ab245908af883a5a18921ad712ecc91ffb85af": "3dcb4e753dd76c86b25b7a4d5a37e43b",
".git/objects/e3/e9ee754c75ae07cc3d19f9b8c1e656cc4946a1": "14066365125dcce5aec8eb1454f0d127",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/e9/76bab65766be5d6f9af666051e2d073e7d0372": "b02850537ac1b71533d0934fb4781585",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/eb/ba31fefda9ed1db2d2042a9047be32573a6889": "449a3426b203c5f854378cdd152179a4",
".git/objects/ed/b55d4deb8363b6afa65df71d1f9fd8c7787f22": "886ebb77561ff26a755e09883903891d",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/fe/3b987e61ed346808d9aa023ce3073530ad7426": "dc7db10bf25046b27091222383ede515",
".git/objects/fe/d09a1cac78ed5925fe2a3d80f244b4fae44782": "d0f6300b99a13386a167d1bd87014a7d",
".git/ORIG_HEAD": "97c6eab1803d8cc4c1806dd8a44ab5d4",
".git/refs/heads/gh-pages": "22f060220041a2effebe19d144103106",
".git/refs/remotes/origin/gh-pages": "22f060220041a2effebe19d144103106",
"assets/AssetManifest.bin": "92ab86275712d68f55b06f1c7b24812e",
"assets/AssetManifest.bin.json": "c48722b7137e5027eea1cd882aedfa30",
"assets/AssetManifest.json": "84691f8962280e94dc9492db3f3fe675",
"assets/assets/game_banner_640x360.jpg": "447724c8f95ddf08c7f57f553a397763",
"assets/assets/game_banner_640x360.png": "19f75d299a1e6fe13df2e1f96d677e54",
"assets/assets/levels.json": "418394a6c9ecd2e5768d3fc5eb1c662a",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "b7d139e52132c81c7d8794ca6c34f688",
"assets/NOTICES": "e3a7ee73d733cee4d281c4b7784e1543",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/shaders/stretch_effect.frag": "23fc0b9e204601c015309bcfc989b939",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"canvaskit/webparagraph/canvaskit.js": "5e5e4fb27c4333aa2924e9dcd2f66333",
"canvaskit/webparagraph/canvaskit.js.symbols": "4ad59e119a5de2977a4f7538062f47ef",
"canvaskit/webparagraph/canvaskit.wasm": "8cecf3b9c2e8270502de9138a21d4e8f",
"canvaskit/wimp.js": "6d8714f96a4bdb92e43e85467ef7451c",
"canvaskit/wimp.js.symbols": "c6d1920b3b6714201ef8c901ec8b8e38",
"canvaskit/wimp.wasm": "9173d3df97ed517649085f35f64592bf",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "213df19371c0fe04132b9589c70c1864",
"game_banner_640x360.png": "19f75d299a1e6fe13df2e1f96d677e54",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "f09decc1bccf6c69fa17a62d69eea0b4",
"/": "f09decc1bccf6c69fa17a62d69eea0b4",
"main.dart.js": "b34b704a60a0ef07cda0b7feb5681ab7",
"manifest.json": "16950faa2fc846789f54d1b87c463b67",
"version.json": "82f05cef8216e09f18dc2ef6218573f4"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
