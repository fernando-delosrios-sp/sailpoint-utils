// === Configuration / required env vars ===
// tenant        : your ISC tenant (e.g. "acme")      [required]
// clientId      : OAuth client id                    [required]
// clientSecret  : OAuth client secret                [required]
// sourceName    : exact source name to resolve       [required]
// domain        : your ISC domain (e.g. "identitynow") [required]

// Helper: safely get env var
function env(name) {
    const v = pm.environment.get(name);
    if (v === undefined || v === null || v === "") {
        throw new Error("Missing required environment variable: " + name);
    }
    return v;
}

// 1) Build URLs and read flags
const tenant       = env("tenant");
const domain       = env("domain");
const clientId     = env("clientId");
const clientSecret = env("clientSecret");
const sourceName   = env("sourceName");

// Collection-level flag
const remoteMode = String(pm.collectionVariables.get("remoteMode") || "").toLowerCase() === "true";

// Auth/token URL – client credentials
const authBase = tenant + ".api." + domain + ".com";
const tokenUrl = "https://" + authBase + "/oauth/token";

// Versioned API bases
const apiBaseV2025 = "https://" + tenant + ".api." + domain + ".com/v2025"; // for sources
const apiBaseBeta  = "https://" + tenant + ".api." + domain + ".com/beta";  // for connector invoke

// 2) Function: get or reuse access token (simple cache in env)
function getToken(callback) {
    const existingToken = pm.environment.get("sp_access_token");
    const expiresAt     = pm.environment.get("sp_access_token_expires_at");

    const now = Date.now();
    if (existingToken && expiresAt && now < Number(expiresAt) - 60000) {
        return callback(null, existingToken);
    }

    const tokenRequestBody = {
        grant_type: "client_credentials",
        client_id: clientId,
        client_secret: clientSecret
    };

    pm.sendRequest({
        url: tokenUrl,
        method: "POST",
        header: {
            "Content-Type": "application/x-www-form-urlencoded"
        },
        body: {
            mode: "urlencoded",
            urlencoded: Object.keys(tokenRequestBody).map(k => ({
                key: k,
                value: tokenRequestBody[k],
                disabled: false
            }))
        }
    }, function (err, res) {
        if (err) {
            return callback(err);
        }
        if (!res || !res.json) {
            return callback(new Error("Token response is empty or invalid"));
        }

        const json = res.json();
        const accessToken = json.access_token;
        const expiresIn   = json.expires_in || 3600;

        if (!accessToken) {
            return callback(new Error("No access_token in OAuth response"));
        }

        pm.environment.set("sp_access_token", accessToken);
        pm.environment.set("sp_access_token_expires_at", String(Date.now() + (expiresIn * 1000)));

        callback(null, accessToken);
    });
}

// 3) Function: list all sources (v2025)
function listSources(accessToken, callback) {
    const url = apiBaseV2025 + "/sources?limit=250";

    pm.sendRequest({
        url: url,
        method: "GET",
        header: {
            "Authorization": "Bearer " + accessToken,
            "Accept": "application/json"
        }
    }, function (err, res) {
        if (err) {
            return callback(err);
        }
        if (!res || !res.json) {
            return callback(new Error("Source response is empty or invalid"));
        }

        const json = res.json();
        let sources = [];

        if (Array.isArray(json)) {
            sources = json;
        } else if (json && Array.isArray(json.items)) {
            sources = json.items;
        } else {
            return callback(new Error("Unexpected sources response shape"));
        }

        callback(null, sources);
    });
}

// 4) Resolve source by exact sourceName
function resolveSourceByName(sources, name) {
    const matches = (sources || []).filter(function (src) {
        return src && typeof src.name === "string" && src.name === name;
    });

    if (matches.length === 0) {
        throw new Error("No source found with exact name: " + name);
    }

    if (matches.length > 1) {
        throw new Error(
            "Multiple sources found with exact name: " + name + ". Use a unique source name."
        );
    }

    return matches[0];
}

// 5) Try common source payload paths for remote invoke connector id
function resolveConnectorIdFromSource(source) {
    if (!source || typeof source !== "object") {
        return null;
    }

    const candidates = [
        source.connectorId,
        source.connectorID,
        source.connector_id,
        source.connector && source.connector.id,
        source.connectorRef && source.connectorRef.id,
        source.platformConnectorId,
        source.connectorAttributes && source.connectorAttributes.connectorId,
        source.connectorAttributes && source.connectorAttributes.connectorID,
        source.connectorAttributes && source.connectorAttributes.platformConnectorId
    ];

    for (let i = 0; i < candidates.length; i += 1) {
        const value = candidates[i];
        if (value !== undefined && value !== null && String(value) !== "") {
            return String(value);
        }
    }

    return null;
}

// 6) Build final config with precedence: body.config > env > connectorAttributes
function buildFinalConfig(connectorAttributes, bodyConfig) {
    const finalConfig = {};

    const bodyCfg = bodyConfig || {};
    const attr = connectorAttributes || {};

    // Get union of keys
    const keys = new Set([
        ...Object.keys(bodyCfg),
        ...Object.keys(attr),
    ]);

    keys.forEach(key => {
        const envValue = pm.environment.get(key);

        if (Object.prototype.hasOwnProperty.call(bodyCfg, key)) {
            // 1) Body config value
            finalConfig[key] = bodyCfg[key];
        } else if (envValue !== undefined && envValue !== null && envValue !== "") {
            // 2) Environment variable wins
            try {
                finalConfig[key] = JSON.parse(envValue);
            } catch (e) {
                finalConfig[key] = envValue;
            }
        } else if (Object.prototype.hasOwnProperty.call(attr, key)) {
            // 3) ConnectorAttributes default
            finalConfig[key] = attr[key];
        }
    });

    return finalConfig;
}

// 7) Inject/extend config (and tag for remoteMode) at root of request body
function applyConfigToRequestBody(connectorAttributes, isRemoteMode) {
    const req = pm.request;

    if (!req.body || req.body.mode !== "raw") {
        throw new Error("Pre-request script expects a raw JSON body.");
    }

    const raw = req.body.raw || "{}";
    let jsonBody;

    try {
        jsonBody = raw && raw.trim() !== "" ? JSON.parse(raw) : {};
    } catch (e) {
        throw new Error("Request body is not valid JSON: " + e.message);
    }

    const existingConfig =
        (jsonBody.config && typeof jsonBody.config === "object")
            ? jsonBody.config
            : {};

    const finalConfig = buildFinalConfig(connectorAttributes, existingConfig);
    jsonBody.config = finalConfig;

    if (isRemoteMode) {
        jsonBody.tag = "latest";
    }

    // Direct assignment; Content-Type stays application/json (or what you set in headers)
    pm.request.body.raw = JSON.stringify(jsonBody, null, 2);
}

// 8) Remote mode headers and URL (beta/platform-connectors)
function applyRemoteModeOverrides(accessToken, resolvedConnectorId) {
    if (!resolvedConnectorId) {
        throw new Error(
            "remoteMode is enabled but the source does not expose a connector identifier for invoke"
        );
    }

    pm.request.url = apiBaseBeta + "/platform-connectors/" + encodeURIComponent(resolvedConnectorId) + "/invoke";

    const headers = pm.request.headers;
    headers.clear();
    headers.add({ key: "Authorization", value: "Bearer " + accessToken });
    headers.add({ key: "Content-Type", value: "application/json" });
    headers.add({ key: "Accept", value: "application/json" });
}

// === Orchestration ===
getToken(function (err, token) {
    if (err) {
        console.error("Error getting token:", err);
        throw err;
    }

    listSources(token, function (err2, sources) {
        if (err2) {
            console.error("Error fetching sources:", err2);
            throw err2;
        }

        let source;
        try {
            source = resolveSourceByName(sources, sourceName);
        } catch (resolveErr) {
            console.error("Error resolving source by name:", resolveErr);
            throw resolveErr;
        }

        const connectorAttributes = source.connectorAttributes || {};
        const resolvedConnectorId = resolveConnectorIdFromSource(source);

        if (remoteMode) {
            applyRemoteModeOverrides(token, resolvedConnectorId);
        }

        applyConfigToRequestBody(connectorAttributes, remoteMode);
    });
});
