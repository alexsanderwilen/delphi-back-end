unit uResponse.Helper;

interface

uses
  Horse,
  System.JSON;

procedure Success(
  Res: THorseResponse;
  const AMessage: string;
  AData: TJSONValue = nil
);

procedure Created(
  Res: THorseResponse;
  const AMessage: string;
  AData: TJSONValue = nil
);

procedure Error(
  Res: THorseResponse;
  const AMessage: string;
  AStatus: Integer = 400
);

implementation

procedure BaseResponse(
  Res: THorseResponse;
  const ASuccess: Boolean;
  const AMessage: string;
  AData: TJSONValue;
  AStatus: Integer
);
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('success', TJSONBool.Create(ASuccess));
    Obj.AddPair('message', AMessage);

    if Assigned(AData) then
      Obj.AddPair('data', AData);

    Res
      .ContentType('application/json')
      .Status(AStatus)
      .Send(Obj.ToJSON);
  finally
    Obj.Free;
  end;
end;

procedure Success(
  Res: THorseResponse;
  const AMessage: string;
  AData: TJSONValue
);
begin
  BaseResponse(Res, True, AMessage, AData, 200);
end;

procedure Created(
  Res: THorseResponse;
  const AMessage: string;
  AData: TJSONValue
);
begin
  BaseResponse(Res, True, AMessage, AData, 201);
end;

procedure Error(
  Res: THorseResponse;
  const AMessage: string;
  AStatus: Integer
);
begin
  BaseResponse(Res, False, AMessage, nil, AStatus);
end;

end.
