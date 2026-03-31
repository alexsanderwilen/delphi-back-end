unit uJWT.Middleware;

interface

uses
  Horse;

procedure JWTMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses
  uJWT.CurrentUser;

procedure JWTMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
begin
  // apenas valida
  CurrentUserId(Req);

  Next;
end;

end.
