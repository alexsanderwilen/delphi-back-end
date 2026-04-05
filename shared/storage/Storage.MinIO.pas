unit Storage.MinIO;

interface

uses
  System.SysUtils,
  System.Classes,
  Storage.MinIOInterface;

type
  EMinIOConfigException = class(Exception);

  TMinIOStorage = class(TInterfacedObject, IStorageService)
  private
    class var FEndpoint: string;
    class var FAccessKey: string;
    class var FSecretKey: string;
    class var FBucket: string;
    class var FRegion: string;
    class var FUseSSL: Boolean;

    class function NormalizeEndpoint(const AEndpoint: string): string; static;
    class function UrlEncodeRFC3986(const AValue: string; const AEncodeSlash: Boolean): string; static;
    class function EncodeObjectName(const AObjectName: string): string; static;
    class function BytesToHex(const ABytes: TBytes): string; static;
    class function HmacSHA256(const AKey: TBytes; const AData: string): TBytes; static;
    class function SHA256Hex(const AData: string): string; static;
    class function GetSignatureKey(
      const ADateStamp, ARegion, AService, ASecretKey: string
    ): TBytes; static;
    class procedure CheckConfigured; static;
    class function GetScheme: string; static;
    class function GetHostHeader: string; static;

    class function GeneratePresignedUrl(
      const AHttpMethod: string;
      const AObjectName: string;
      const AExpiresInSeconds: Integer = 300
    ): string; static;

  public
    class procedure Configure(
      const AEndpoint: string;
      const AAccessKey: string;
      const ASecretKey: string;
      const ABucket: string;
      const ARegion: string = 'us-east-1';
      const AUseSSL: Boolean = True
    ); static;

    class function GeneratePresignedGetUrl(
      const AObjectName: string;
      const AExpiresInSeconds: Integer = 300
    ): string; static;

    class function GeneratePresignedPutUrl(
      const AObjectName: string;
      const AExpiresInSeconds: Integer = 300
    ): string; static;

    class function GeneratePresignedHeadUrl(
      const AObjectName: string;
      const AExpiresInSeconds: Integer = 300
    ): string; static;

    class function GeneratePresignedDeleteUrl(
      const AObjectName: string;
      const AExpiresInSeconds: Integer = 300
    ): string; static;

    function UploadFile(
      const AObjectName: string;
      AStream: TStream;
      const AContentType: string
    ): Boolean;

    function DeleteFile(
      const AObjectName: string
    ): Boolean;

    function FileExists(
      const AObjectName: string
    ): Boolean;

    function GetSignedUrl(
      const AObjectName: string;
      const AExpiresInSeconds: Integer = 300
    ): string;
  end;

implementation

uses
  System.Hash,
  System.DateUtils,
  System.Net.HttpClient,
  System.Net.URLClient;

{ TMinIOStorage }

class procedure TMinIOStorage.Configure(
  const AEndpoint: string;
  const AAccessKey: string;
  const ASecretKey: string;
  const ABucket: string;
  const ARegion: string;
  const AUseSSL: Boolean
);
begin
  FEndpoint := NormalizeEndpoint(AEndpoint);
  FAccessKey := Trim(AAccessKey);
  FSecretKey := Trim(ASecretKey);
  FBucket := Trim(ABucket);
  FRegion := Trim(ARegion);
  FUseSSL := AUseSSL;
end;

class procedure TMinIOStorage.CheckConfigured;
begin
  if Trim(FEndpoint).IsEmpty then
    raise EMinIOConfigException.Create('MinIO Endpoint não configurado.');

  if Trim(FAccessKey).IsEmpty then
    raise EMinIOConfigException.Create('MinIO Access Key não configurada.');

  if Trim(FSecretKey).IsEmpty then
    raise EMinIOConfigException.Create('MinIO Secret Key não configurada.');

  if Trim(FBucket).IsEmpty then
    raise EMinIOConfigException.Create('MinIO Bucket não configurado.');

  if Trim(FRegion).IsEmpty then
    raise EMinIOConfigException.Create('MinIO Region não configurada.');
end;

class function TMinIOStorage.NormalizeEndpoint(const AEndpoint: string): string;
begin
  Result := Trim(AEndpoint);

  if Result.StartsWith('https://', True) then
    Result := Result.Substring(8)
  else if Result.StartsWith('http://', True) then
    Result := Result.Substring(7);

  while Result.EndsWith('/') do
    Result := Result.Substring(0, Result.Length - 1);
end;

class function TMinIOStorage.GetScheme: string;
begin
  if FUseSSL then
    Result := 'https'
  else
    Result := 'http';
end;

class function TMinIOStorage.GetHostHeader: string;
begin
  Result := LowerCase(FEndpoint);
end;

class function TMinIOStorage.UrlEncodeRFC3986(
  const AValue: string;
  const AEncodeSlash: Boolean
): string;
const
  Unreserved = ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~'];
var
  Bytes: TBytes;
  I: Integer;
  C: AnsiChar;
begin
  Result := '';
  Bytes := TEncoding.UTF8.GetBytes(AValue);

  for I := 0 to High(Bytes) do
  begin
    C := AnsiChar(Bytes[I]);

    if Char(C) in Unreserved then
      Result := Result + Char(C)
    else if (not AEncodeSlash) and (C = '/') then
      Result := Result + '/'
    else
      Result := Result + '%' + IntToHex(Bytes[I], 2);
  end;
end;

class function TMinIOStorage.EncodeObjectName(const AObjectName: string): string;
begin
  Result := UrlEncodeRFC3986(Trim(AObjectName), False);
end;

class function TMinIOStorage.BytesToHex(const ABytes: TBytes): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(ABytes) do
    Result := Result + LowerCase(IntToHex(ABytes[I], 2));
end;

class function TMinIOStorage.HmacSHA256(const AKey: TBytes; const AData: string): TBytes;
begin
  Result := THashSHA2.GetHMACAsBytes(
    TEncoding.UTF8.GetBytes(AData),
    AKey,
    THashSHA2.TSHA2Version.SHA256
  );
end;

class function TMinIOStorage.SHA256Hex(const AData: string): string;
begin
  Result := LowerCase(
    THashSHA2.GetHashString(AData, THashSHA2.TSHA2Version.SHA256)
  );
end;

class function TMinIOStorage.GetSignatureKey(
  const ADateStamp, ARegion, AService, ASecretKey: string
): TBytes;
var
  KDate: TBytes;
  KRegion: TBytes;
  KService: TBytes;
begin
  KDate := HmacSHA256(TEncoding.UTF8.GetBytes('AWS4' + ASecretKey), ADateStamp);
  KRegion := HmacSHA256(KDate, ARegion);
  KService := HmacSHA256(KRegion, AService);
  Result := HmacSHA256(KService, 'aws4_request');
end;

class function TMinIOStorage.GeneratePresignedUrl(
  const AHttpMethod: string;
  const AObjectName: string;
  const AExpiresInSeconds: Integer
): string;
var
  LUtcNow: TDateTime;
  LAmzDate: string;
  LDateStamp: string;
  LCredentialScope: string;
  LCanonicalUri: string;
  LCanonicalHeaders: string;
  LSignedHeaders: string;
  LCanonicalQueryString: string;
  LCanonicalRequest: string;
  LStringToSign: string;
  LSigningKey: TBytes;
  LSignature: string;
  LObjectName: string;
  LCredential: string;
  LHost: string;
begin
  CheckConfigured;

  LObjectName := Trim(AObjectName);
  if LObjectName.IsEmpty then
    raise Exception.Create('ObjectName não informado.');

  if (AExpiresInSeconds <= 0) or (AExpiresInSeconds > 604800) then
    raise Exception.Create('A expiração deve estar entre 1 e 604800 segundos.');

  LUtcNow := TTimeZone.Local.ToUniversalTime(Now);

  LAmzDate := FormatDateTime('yyyymmdd"T"hhnnss"Z"', LUtcNow);
  LDateStamp := FormatDateTime('yyyymmdd', LUtcNow);

  LCredentialScope := LDateStamp + '/' + FRegion + '/s3/aws4_request';
  LCredential := FAccessKey + '/' + LCredentialScope;

  LHost := GetHostHeader;
  LCanonicalUri := '/' + UrlEncodeRFC3986(FBucket, True) + '/' + EncodeObjectName(LObjectName);
  LCanonicalHeaders := 'host:' + LHost + #10;
  LSignedHeaders := 'host';

  LCanonicalQueryString :=
      'X-Amz-Algorithm=' + UrlEncodeRFC3986('AWS4-HMAC-SHA256', True) + '&' +
      'X-Amz-Credential=' + UrlEncodeRFC3986(LCredential, True) + '&' +
      'X-Amz-Date=' + UrlEncodeRFC3986(LAmzDate, True) + '&' +
      'X-Amz-Expires=' + IntToStr(AExpiresInSeconds) + '&' +
      'X-Amz-SignedHeaders=' + UrlEncodeRFC3986(LSignedHeaders, True);

  LCanonicalRequest :=
      UpperCase(AHttpMethod) + #10 +
      LCanonicalUri + #10 +
      LCanonicalQueryString + #10 +
      LCanonicalHeaders + #10 +
      LSignedHeaders + #10 +
      'UNSIGNED-PAYLOAD';

  LStringToSign :=
      'AWS4-HMAC-SHA256' + #10 +
      LAmzDate + #10 +
      LCredentialScope + #10 +
      SHA256Hex(LCanonicalRequest);

  LSigningKey := GetSignatureKey(LDateStamp, FRegion, 's3', FSecretKey);
  LSignature := BytesToHex(HmacSHA256(LSigningKey, LStringToSign));

  Result :=
      GetScheme + '://' + FEndpoint +
      LCanonicalUri + '?' +
      LCanonicalQueryString + '&X-Amz-Signature=' + LSignature;
end;

class function TMinIOStorage.GeneratePresignedGetUrl(
  const AObjectName: string;
  const AExpiresInSeconds: Integer
): string;
begin
  Result := GeneratePresignedUrl('GET', AObjectName, AExpiresInSeconds);
end;

class function TMinIOStorage.GeneratePresignedPutUrl(
  const AObjectName: string;
  const AExpiresInSeconds: Integer
): string;
begin
  Result := GeneratePresignedUrl('PUT', AObjectName, AExpiresInSeconds);
end;

class function TMinIOStorage.GeneratePresignedHeadUrl(
  const AObjectName: string;
  const AExpiresInSeconds: Integer
): string;
begin
  Result := GeneratePresignedUrl('HEAD', AObjectName, AExpiresInSeconds);
end;

class function TMinIOStorage.GeneratePresignedDeleteUrl(
  const AObjectName: string;
  const AExpiresInSeconds: Integer
): string;
begin
  Result := GeneratePresignedUrl('DELETE', AObjectName, AExpiresInSeconds);
end;

function TMinIOStorage.UploadFile(
  const AObjectName: string;
  AStream: TStream;
  const AContentType: string
): Boolean;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  LUrl: string;
  LHeaders: TNetHeaders;
begin
  if not Assigned(AStream) then
    raise Exception.Create('Stream não informado.');

  Client := THTTPClient.Create;
  try
    LUrl := GeneratePresignedPutUrl(AObjectName, 300);

    SetLength(LHeaders, 0);
    if not Trim(AContentType).IsEmpty then
    begin
      SetLength(LHeaders, 1);
      LHeaders[0].Name := 'Content-Type';
      LHeaders[0].Value := AContentType;
    end;

    AStream.Position := 0;
    Response := Client.Put(LUrl, AStream, nil, LHeaders);

    Result := Response.StatusCode in [200, 201];
  finally
    Client.Free;
  end;
end;

function TMinIOStorage.DeleteFile(
  const AObjectName: string
): Boolean;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  LUrl: string;
begin
  Client := THTTPClient.Create;
  try
    LUrl := GeneratePresignedDeleteUrl(AObjectName, 300);
    Response := Client.Delete(LUrl);
    Result := Response.StatusCode in [200, 204];
  finally
    Client.Free;
  end;
end;

function TMinIOStorage.FileExists(
  const AObjectName: string
): Boolean;
var
  Client: THTTPClient;
  Response: IHTTPResponse;
  LUrl: string;
begin
  Client := THTTPClient.Create;
  try
    LUrl := GeneratePresignedHeadUrl(AObjectName, 300);
    Response := Client.Head(LUrl);
    Result := Response.StatusCode = 200;
  finally
    Client.Free;
  end;
end;

function TMinIOStorage.GetSignedUrl(
  const AObjectName: string;
  const AExpiresInSeconds: Integer
): string;
begin
  Result := GeneratePresignedGetUrl(AObjectName, AExpiresInSeconds);
end;

end.
