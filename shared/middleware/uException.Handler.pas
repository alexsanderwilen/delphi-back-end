unit uException.Handler;

interface

uses
  Horse;

procedure ExceptionMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);

implementation

uses
  System.SysUtils,
  System.JSON,
  uApp.Exception;

procedure ExceptionMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
  Json: TJSONObject;
  StatusCode: Integer;
begin
  try
    Next;
  except
    on E: Exception do
    begin
      StatusCode := 500;

      if E is EAppException then
        StatusCode := EAppException(E).StatusCode;

      Json := TJSONObject.Create;
      try
        Json.AddPair('success', TJSONBool.Create(False));
        Json.AddPair('message', E.Message);

        Res
          .ContentType('application/json')
          .Status(StatusCode)
          .Send(Json.ToJSON);
      finally
        Json.Free;
      end;
    end;
  end;
end;

end.
