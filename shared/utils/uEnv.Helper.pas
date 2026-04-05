unit uEnv.Helper;

interface

uses
  System.SysUtils,
  System.Classes,
  Winapi.Windows;

type
  EEnvException = class(Exception);

  TEnvHelper = class
  public
    class procedure LoadFromFile(const AFileName: string = '.env'); static;
    class function GetValue(const AName: string; const ADefault: string = ''): string; static;
    class function RequireValue(const AName: string): string; static;
    class function GetBool(const AName: string; const ADefault: Boolean = False): Boolean; static;
  end;

implementation

class procedure TEnvHelper.LoadFromFile(const AFileName: string);
var
  LFileName: string;
  LLines: TStringList;
  I: Integer;
  LLine: string;
  LName: string;
  LValue: string;
  LPos: Integer;
begin
  LFileName := ExpandFileName(AFileName);

  if not FileExists(LFileName) then
    raise EEnvException.CreateFmt('Arquivo .env não encontrado: %s', [LFileName]);

  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(LFileName, TEncoding.UTF8);

    for I := 0 to LLines.Count - 1 do
    begin
      LLine := Trim(LLines[I]);

      if LLine.IsEmpty or LLine.StartsWith('#') then
        Continue;

      LPos := Pos('=', LLine);
      if LPos <= 1 then
        Continue;

      LName := Trim(Copy(LLine, 1, LPos - 1));
      LValue := Trim(Copy(LLine, LPos + 1, MaxInt));

      if (LValue.Length >= 2) and
         (((LValue[1] = '"') and (LValue[LValue.Length] = '"')) or
          ((LValue[1] = '''') and (LValue[LValue.Length] = ''''))) then
        LValue := Copy(LValue, 2, LValue.Length - 2);

      SetEnvironmentVariable(PChar(LName), PChar(LValue));
    end;
  finally
    LLines.Free;
  end;
end;

class function TEnvHelper.GetValue(const AName: string; const ADefault: string): string;
begin
  Result := GetEnvironmentVariable(AName);
  if Result.IsEmpty then
    Result := ADefault;
end;

class function TEnvHelper.RequireValue(const AName: string): string;
begin
  Result := GetEnvironmentVariable(AName);

  if Result.IsEmpty then
    raise EEnvException.CreateFmt('Variável de ambiente obrigatória não definida: %s', [AName]);
end;

class function TEnvHelper.GetBool(const AName: string; const ADefault: Boolean): Boolean;
var
  LValue: string;
begin
  LValue := Trim(LowerCase(GetEnvironmentVariable(AName)));

  if LValue.IsEmpty then
    Exit(ADefault);

  Result := (LValue = '1') or
            (LValue = 'true') or
            (LValue = 'yes') or
            (LValue = 'y') or
            (LValue = 'sim') or
            (LValue = 's');
end;

end.
