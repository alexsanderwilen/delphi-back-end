unit uApp.Exception;

interface

uses
  System.SysUtils;

type
  EAppException = class(Exception)
  private
    FStatusCode: Integer;
  public
    constructor Create(const AMessage: string; AStatusCode: Integer = 400);
    property StatusCode: Integer read FStatusCode;
  end;

implementation

constructor EAppException.Create(const AMessage: string; AStatusCode: Integer);
begin
  inherited Create(AMessage);
  FStatusCode := AStatusCode;
end;

end.
