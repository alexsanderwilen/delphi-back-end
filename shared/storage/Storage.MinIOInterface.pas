unit Storage.MinIOInterface;

interface

uses
  System.Classes;

type
  IStorageService = interface
    ['{8A3DFD7C-95C2-4E4E-9D84-1234567890AB}']

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

end.
