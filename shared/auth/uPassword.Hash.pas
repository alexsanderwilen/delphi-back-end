unit uPassword.Hash;

interface

type
  TPasswordHash = class
  public
    class function Hash(const APassword: string): string; static;
    class function Verify(const APassword, AHash: string): Boolean; static;
  end;

implementation

uses
  BCrypt;

class function TPasswordHash.Hash(const APassword: string): string;
begin
  Result := TBCrypt.GenerateHash(APassword, 12);
end;

class function TPasswordHash.Verify(const APassword, AHash: string): Boolean;
begin
  Result := TBCrypt.CompareHash(APassword, AHash);
end;

end.
