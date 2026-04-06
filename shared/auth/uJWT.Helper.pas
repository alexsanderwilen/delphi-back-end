unit uJWT.Helper;

interface

type
  TJWTToken = class
  public
    class function GenerateToken(
      const AUserId: Int64;
      const ALogin, ANome, ARole, AFotoUrl: string
    ): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  JOSE.Core.JWT,
  JOSE.Core.JWA,
  JOSE.Core.Builder,
  JOSE.Types.JSON,
  JOSE.Types.Bytes,
  uJWT.Config;

class function TJWTToken.GenerateToken(
  const AUserId: Int64;
  const ALogin, ANome, ARole, AFotoUrl: string
): string;
var
  LToken: TJWT;
begin
  LToken := TJWT.Create;
  try
    LToken.Claims.IssuedAt := Now;
    LToken.Claims.Expiration := IncMinute(Now, TJWTConfig.ExpirationMinutes);
    LToken.Claims.Issuer := TJWTConfig.Issuer;
    LToken.Claims.Subject := AUserId.ToString;

    LToken.Claims.SetClaimOfType<string>('login', ALogin);
    LToken.Claims.SetClaimOfType<string>('nome', ANome);
    LToken.Claims.SetClaimOfType<string>('role', ARole);
    LToken.Claims.SetClaimOfType<string>('fotoUrl', AFotoUrl);

    Result := TJOSE.SHA256CompactToken(TJWTConfig.SecretKey, LToken);
  finally
    LToken.Free;
  end;
end;

end.
