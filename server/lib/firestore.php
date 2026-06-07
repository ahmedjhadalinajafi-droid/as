<?php
// ============================================================================
//  firestore.php — minimal Firestore REST client using the Web API key.
//  Works because the project's security rules are open (allow if true).
// ============================================================================

require_once __DIR__ . '/../config.php';

function fs_base(): string {
    return 'https://firestore.googleapis.com/v1/projects/'
        . FIREBASE_PROJECT_ID . '/databases/(default)/documents';
}

// Encodes a PHP value into a Firestore typed value.
function fs_value($v): array {
    if (is_bool($v))   return ['booleanValue' => $v];
    if (is_int($v))    return ['integerValue' => (string)$v];
    if (is_float($v))  return ['doubleValue' => $v];
    if ($v === null)   return ['nullValue' => null];
    if ($v instanceof DateTime) {
        return ['timestampValue' => $v->format('Y-m-d\TH:i:s\Z')];
    }
    return ['stringValue' => (string)$v];
}

// Decodes a Firestore typed value back into a PHP value.
function fs_decode_value(array $v) {
    $k = array_key_first($v);
    return match ($k) {
        'booleanValue'   => $v[$k],
        'integerValue'   => (int)$v[$k],
        'doubleValue'    => (float)$v[$k],
        'timestampValue' => $v[$k],
        'nullValue'      => null,
        default          => $v[$k],
    };
}

function fs_decode_fields(array $doc): array {
    $out = ['_name' => $doc['name'] ?? ''];
    $out['_id'] = $out['_name'] !== '' ? basename($out['_name']) : '';
    foreach (($doc['fields'] ?? []) as $key => $val) {
        $out[$key] = fs_decode_value($val);
    }
    return $out;
}

function fs_request(string $method, string $path, ?array $fields = null): array {
    $url = fs_base() . $path
        . (str_contains($path, '?') ? '&' : '?')
        . 'key=' . FIREBASE_API_KEY;

    $ch = curl_init($url);
    $opts = [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_HTTPHEADER     => ['Content-Type: application/json'],
    ];
    if ($fields !== null) {
        $body = [];
        foreach ($fields as $k => $v) $body[$k] = fs_value($v);
        $opts[CURLOPT_POSTFIELDS] = json_encode(['fields' => $body]);
    }
    curl_setopt_array($ch, $opts);
    $res  = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return [$code, json_decode((string)$res, true)];
}

// Returns all documents in a collection as decoded arrays.
function fs_list(string $collection): array {
    $docs = [];
    $pageToken = '';
    do {
        $path = '/' . $collection . '?pageSize=200'
            . ($pageToken ? '&pageToken=' . urlencode($pageToken) : '');
        [$code, $data] = fs_request('GET', $path);
        if ($code !== 200) break;
        foreach (($data['documents'] ?? []) as $doc) {
            $docs[] = fs_decode_fields($doc);
        }
        $pageToken = $data['nextPageToken'] ?? '';
    } while ($pageToken);
    return $docs;
}

function fs_add(string $collection, array $fields): array {
    return fs_request('POST', '/' . $collection, $fields);
}

function fs_update(string $collection, string $id, array $fields): array {
    $mask = '';
    foreach (array_keys($fields) as $k) {
        $mask .= ($mask ? '&' : '?') . 'updateMask.fieldPaths=' . urlencode($k);
    }
    return fs_request('PATCH', '/' . $collection . '/' . $id . $mask, $fields);
}

function fs_delete(string $collection, string $id): array {
    return fs_request('DELETE', '/' . $collection . '/' . $id);
}
