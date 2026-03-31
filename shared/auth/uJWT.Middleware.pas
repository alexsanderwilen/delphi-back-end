unit uJWT.Middleware;

interface

uses
  Horse;

procedure JWTMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);

function RequireRole(const ARole: string): THorseCallback;
function RequireAdmin: THorseCallback;

implementation

uses
  uJWT.CurrentUser,
  uApp.Exception,
  System.SysUtils;

procedure JWTMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  // só valida token
  CurrentUserId(Req);
  Next;
end;

function RequireRole(const ARole: string): THorseCallback;
begin
  Result :=
    procedure(Req: THorseRequest; Res: THorseResponse; Next: TProc)
    var
      UserRole: string;
    begin
      UserRole := CurrentUserRole(Req);

      if not SameText(UserRole, ARole) then
        raise EAppException.Create('Acesso negado', 403);

      Next;
    end;
end;

function RequireAdmin: THorseCallback;
begin
  Result := RequireRole('admin');
end;

end.
