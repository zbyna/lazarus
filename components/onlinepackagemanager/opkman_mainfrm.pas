{
 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

 Author: Balázs Székely
 Abstract:
   Implementation of the main dialog.
}
unit opkman_mainfrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, contnrs,
  StdCtrls, ExtCtrls, Buttons, Menus, ComCtrls, IDECommands, LazFileUtils,
  LCLIntf, fpjson, opkman_downloader, opkman_installer,
  PackageIntf;

type

  { TMainFrm }

  TMainFrm = class(TForm)
    cbPackageCategory: TComboBox;
    cbPackageState: TComboBox;
    cbPackageType: TComboBox;
    imTBDis: TImageList;
    miCreateRepository: TMenuItem;
    miCreateRepositoryPackage: TMenuItem;
    tbCleanUp1: TToolButton;
    tbOptions: TToolButton;
    cbAll: TCheckBox;
    cbFilterBy: TComboBox;
    edFilter: TEdit;
    imTree: TImageList;
    lbFilterBy: TLabel;
    miJSONShow: TMenuItem;
    miJSONHide: TMenuItem;
    mJSON: TMemo;
    pmMemo: TPopupMenu;
    pnFilter: TPanel;
    pnMessage: TPanel;
    pnToolBar: TPanel;
    pnTop: TPanel;
    pnMain: TPanel;
    pmTree: TPopupMenu;
    pmRepository: TPopupMenu;
    SDD: TSelectDirectoryDialog;
    spCollapse: TSpeedButton;
    spClear: TSpeedButton;
    spExpand: TSpeedButton;
    tbButtons: TToolBar;
    imTBNor: TImageList;
    tbDownload: TToolButton;
    tbInstall: TToolButton;
    tbRefresh: TToolButton;
    tbCleanUp: TToolButton;
    tbCreate: TToolButton;
    tbUpdate: TToolButton;
    procedure miCreateRepositoryPackageClick(Sender: TObject);
    procedure pnToolBarResize(Sender: TObject);
    procedure tbCleanUpClick(Sender: TObject);
    procedure tbDownloadClick(Sender: TObject);
    procedure tbInstallClick(Sender: TObject);
    procedure tbOptionsClick(Sender: TObject);
    procedure tbRefreshClick(Sender: TObject);
    procedure cbAllClick(Sender: TObject);
    procedure cbFilterByChange(Sender: TObject);
    procedure cbPackageCategoryChange(Sender: TObject);
    procedure cbPackageStateChange(Sender: TObject);
    procedure cbPackageTypeChange(Sender: TObject);
    procedure edFilterChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormShow(Sender: TObject);
    procedure miJSONShowClick(Sender: TObject);
    procedure pnMainResize(Sender: TObject);
    procedure pnTopResize(Sender: TObject);
    procedure spClearClick(Sender: TObject);
    procedure spExpandClick(Sender: TObject);
    procedure tbUpdateClick(Sender: TObject);
  private
    FHintTimeOut: Integer;
    procedure EnableDisableControls(const AEnable: Boolean);
    procedure SetupMessage(const AMessage: String = '');
    procedure SetupControls;
    procedure GetPackageList;
    procedure ShowOptions;
    procedure DoOnChecking(Sender: TObject; const AIsAllChecked: Boolean);
    procedure DoOnChecked(Sender: TObject);
    procedure DoOnJSONProgress(Sender: TObject);
    procedure DoOnJSONDownloadCompleted(Sender: TObject; AJSON: TJSONStringType; AErrTyp: TErrorType; const AErrMsg: String = '');
    function IsSomethingChecked(const AIsUpdate: Boolean = False): Boolean;
    function Download(const ADstDir: String; var ADoExtract: Boolean): TModalResult;
    function Extract(const ASrcDir, ADstDir: String; var ADoOpen: Boolean; const AIsUpdate: Boolean = False): TModalResult;
    function Install(var AInstallStatus: TInstallStatus; var ANeedToRebuild: Boolean): TModalResult;
    function UpdateP(const ADstDir: String; var ADoExtract: Boolean): TModalResult;
  public
  end;

var
  MainFrm: TMainFrm;

implementation

uses opkman_serializablepackages, opkman_visualtree, opkman_const, opkman_common,
     opkman_progressfrm, opkman_zipper, opkman_packagelistfrm, opkman_options,
     opkman_optionsfrm, opkman_createrepositorypackage;
{$R *.lfm}

{ TMainFrm }

procedure TMainFrm.FormCreate(Sender: TObject);
begin
  InitLocalRepository;
  Options := TOptions.Create(LocalRepositoryConfigFile);
  VisualTree := TVisualTree.Create(pnMain, imTree, pmTree);
  VisualTree.OnChecking := @DoOnChecking;
  VisualTree.OnChecked := @DoOnChecked;
  SerializablePackages := TSerializablePackages.Create;
  PackageDownloader := TPackageDownloader.Create(Options.RemoteRepository);
  PackageDownloader.OnJSONProgress := @DoOnJSONProgress;
  PackageDownloader.OnJSONDownloadCompleted := @DoOnJSONDownloadCompleted;
  InstallPackageList := TObjectList.Create(True);
  FHintTimeOut := Application.HintHidePause;
  Application.HintHidePause := 1000000;
end;

procedure TMainFrm.FormDestroy(Sender: TObject);
begin
  PackageDownloader.Free;
  SerializablePackages.Free;
  VisualTree.Free;
  Options.Free;
  InstallPackageList.Free;
  Application.HintHidePause := FHintTimeOut;
end;

procedure TMainFrm.FormKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #27 then
    Close;
end;

procedure TMainFrm.FormShow(Sender: TObject);
begin
  SetupControls;
  GetPackageList;
end;

procedure TMainFrm.GetPackageList;
begin
  VisualTree.VST.Clear;
  if SerializablePackages.Count > 0 then
    SerializablePackages.Clear;
  EnableDisableControls(False);
  SetupMessage(rsMessageDownload);
  PackageDownloader.DownloadJSON(10000);
end;

function TMainFrm.IsSomethingChecked(const AIsUpdate: Boolean = False): Boolean;
begin
  Result := VisualTree.VST.CheckedCount > 0;
  if Result then
  begin
    if not AIsUpdate then
      if VisualTree.ResolveDependencies = mrCancel then
        Exit;
    VisualTree.GetPackageList;
    VisualTree.UpdatePackageStates;
  end
  else
    MessageDlgEx(rsNoPackageToDownload, mtInformation, [mbOk], Self)
end;

function TMainFrm.Download(const ADstDir: String; var ADoExtract: Boolean): TModalResult;
begin
  ADoExtract := False;
  ProgressFrm := TProgressFrm.Create(MainFrm);
  try
    ProgressFrm.SetupControls(0);
    PackageDownloader.OnPackageDownloadProgress := @ProgressFrm.DoOnPackageDownloadProgress;
    PackageDownloader.OnPackageDownloadError := @ProgressFrm.DoOnPackageDownloadError;
    PackageDownloader.OnPackageDownloadCompleted := @ProgressFrm.DoOnPackageDownloadCompleted;
    PackageDownloader.DownloadPackages(ADstDir);
    Result := ProgressFrm.ShowModal;
    if Result = mrOK then
      ADoExtract := ProgressFrm.cbExtractOpen.Checked;
  finally
    ProgressFrm.Free;
  end;
end;

function TMainFrm.Extract(const ASrcDir, ADstDir: String; var ADoOpen: Boolean;
  const AIsUpdate: Boolean = False): TModalResult;
begin
  ProgressFrm := TProgressFrm.Create(MainFrm);
  try
    PackageUnzipper := TPackageUnzipper.Create;
    try
      ProgressFrm.SetupControls(1);
      PackageUnzipper.OnZipProgress := @ProgressFrm.DoOnZipProgress;
      PackageUnzipper.OnZipError := @ProgressFrm.DoOnZipError;
      PackageUnzipper.OnZipCompleted := @ProgressFrm.DoOnZipCompleted;
      PackageUnzipper.StartUnZip(ASrcDir, ADstDir, AIsUpdate);
      Result := ProgressFrm.ShowModal;
      if Result = mrOk then
        ADoOpen := ProgressFrm.cbExtractOpen.Checked;
    finally
      if Assigned(PackageUnzipper) then
        PackageUnzipper := nil;
    end;
 finally
   ProgressFrm.Free;
 end;
end;

function TMainFrm.Install(var AInstallStatus: TInstallStatus;
  var ANeedToRebuild: Boolean): TModalResult;
begin
  ProgressFrm := TProgressFrm.Create(MainFrm);
  try
    ProgressFrm.SetupControls(2);
    Result := ProgressFrm.ShowModal;
    if Result = mrOk then
    begin
      AInstallStatus := ProgressFrm.InstallStatus;
      ANeedToRebuild := ProgressFrm.NeedToRebuild;
    end;
  finally
    ProgressFrm.Free;
  end;
end;

function TMainFrm.UpdateP(const ADstDir: String; var ADoExtract: Boolean): TModalResult;
begin
  ADoExtract := False;
  ProgressFrm := TProgressFrm.Create(MainFrm);
  try
    ProgressFrm.SetupControls(3);
    PackageDownloader.OnPackageDownloadProgress := @ProgressFrm.DoOnPackageDownloadProgress;
    PackageDownloader.OnPackageDownloadError := @ProgressFrm.DoOnPackageDownloadError;
    PackageDownloader.OnPackageDownloadCompleted := @ProgressFrm.DoOnPackageDownloadCompleted;
    PackageDownloader.OnPackageUpdateProgress := @ProgressFrm.DoOnPackageUpdateProgress;
    PackageDownloader.OnPackageUpdateCompleted := @ProgressFrm.DoOnPackageUpdateCompleted;
    PackageDownloader.UpdatePackages(ADstDir);
    Result := ProgressFrm.ShowModal;
    if Result = mrOK then
      ADoExtract := ProgressFrm.cbExtractOpen.Checked;
  finally
    ProgressFrm.Free;
  end;
end;

procedure TMainFrm.DoOnJSONDownloadCompleted(Sender: TObject; AJSON: TJSONStringType; AErrTyp: TErrorType; const AErrMsg: String = '');
begin
  case AErrTyp of
    etNone:
      begin
        if (not SerializablePackages.JSONToPackages(AJSON)) or (SerializablePackages.Count = 0) then
        begin
          EnableDisableControls(True);
          SetupMessage(rsMessageNoPackage);
          MessageDlgEx(rsMessageError1 + sLineBreak + SerializablePackages.LastError, mtInformation, [mbOk], Self);
          Exit;
        end;
        EnableDisableControls(True);
        SetupMessage;
        mJSON.Text := AJSON;
        cbAll.Checked := False;
        VisualTree.PopulateTree;
        Caption := rsLazarusPackageManager + '(' + IntToStr(SerializablePackages.Count) + ' ' + rsMainFrmCaption + ')';
      end;
    etConfig:
      begin
        EnableDisableControls(True);
        SetupMessage(rsMessageNoPackage);
        Caption := rsLazarusPackageManager;
        if MessageDlgEx('"' + AErrMsg + '"', mtConfirmation, [mbYes, mbNo], Self) = mrYes then
          ShowOptions;
      end;
    etTimeOut, etHTTPClient:
      begin
        EnableDisableControls(True);
        SetupMessage(rsMessageNoPackage);
        Caption := rsLazarusPackageManager;
        MessageDlgEx(rsMessageError0 + sLineBreak + '"' + AErrMsg + '"', mtInformation, [mbOk], Self);
      end;
  end;
end;

procedure TMainFrm.ShowOptions;
begin
  OptionsFrm := TOptionsFrm.Create(MainFrm);
  try
    OptionsFrm.SetupControls;
    if OptionsFrm.ShowModal = mrOk then
    begin
      tbRefresh.Enabled := Options.RemoteRepository <> '';
      GetPackageList;
    end;
  finally
    OptionsFrm.Free;
  end;
end;

procedure TMainFrm.EnableDisableControls(const AEnable: Boolean);
begin
  cbAll.Enabled := (AEnable) and (SerializablePackages.Count > 0);
  cbFilterBy.Enabled := (AEnable) and (SerializablePackages.Count > 0);
  pnFilter.Enabled := (AEnable) and (SerializablePackages.Count > 0);
  cbPackageState.Enabled := (AEnable) and (SerializablePackages.Count > 0);
  cbPackageType.Enabled := (AEnable) and (SerializablePackages.Count > 0);

  spExpand.Enabled := (AEnable) and (SerializablePackages.Count > 0);
  spCollapse.Enabled := (AEnable) and (SerializablePackages.Count > 0);
  VisualTree.VST.Enabled := (AEnable) and (SerializablePackages.Count > 0);
  if edFilter.CanFocus then
    edFilter.SetFocus;
  tbRefresh.Enabled := (AEnable) and (Trim(Options.RemoteRepository) <> '');
  tbDownload.Enabled := (AEnable) and (SerializablePackages.Count > 0) and (VisualTree.VST.CheckedCount > 0);
  tbInstall.Enabled := (AEnable) and (SerializablePackages.Count > 0) and (VisualTree.VST.CheckedCount > 0);
  tbUpdate.Enabled :=  (AEnable) and (SerializablePackages.Count > 0) and (VisualTree.VST.CheckedCount > 0);
  tbCleanUp.Enabled := (AEnable) and (SerializablePackages.Count > 0);
  tbCreate.Enabled := (AEnable);
  tbOptions.Enabled := (AEnable);
end;

procedure TMainFrm.SetupMessage(const AMessage: String = '');
begin
  if AMessage = '' then
  begin
    pnMessage.SendToBack;
    pnMessage.Visible := False;
  end
  else
  begin
    pnMessage.Caption := AMessage;
    pnMessage.Visible := True;
    pnMessage.BringToFront;
    Application.ProcessMessages;
  end;
end;

procedure TMainFrm.DoOnChecking(Sender: TObject; const AIsAllChecked: Boolean);
begin
  cbAll.OnClick := nil;
  cbAll.Checked := AIsAllChecked;
  cbAll.OnClick := @cbAllClick;
end;

procedure TMainFrm.DoOnChecked(Sender: TObject);
begin
  EnableDisableControls(True);
end;

procedure TMainFrm.DoOnJSONProgress(Sender: TObject);
begin
  Application.ProcessMessages;
end;

procedure TMainFrm.cbAllClick(Sender: TObject);
begin
  VisualTree.CheckNodes(cbAll.Checked);
end;

procedure TMainFrm.cbFilterByChange(Sender: TObject);
begin
  VisualTree.ResetFilter;
  case cbFilterBy.ItemIndex of
    0..1, 4..9, 11..12:
      begin
        cbPackageType.Visible := False;
        cbPackageState.Visible := False;
        cbPackageCategory.Visible := False;
        pnFilter.Visible := True;
        edFilter.Text := '';
        edFilter.SetFocus;
      end;
   2: begin
        pnFilter.Visible := False;
        cbPackageType.Visible := False;
        cbPackageState.Visible := False;
        cbPackageCategory.Visible := True;
        cbPackageCategory.ItemIndex := 0;
        cbPackageCategory.SetFocus;
      end;
   3: begin
        pnFilter.Visible := False;
        cbPackageType.Visible := False;
        cbPackageState.Visible := True;
        cbPackageCategory.Visible := False;
        cbPackageState.ItemIndex := 0;
        cbPackageState.SetFocus;
      end;
   10: begin
        pnFilter.Visible := False;
        cbPackageState.Visible := False;
        cbPackageType.Visible := True;
        cbPackageCategory.Visible := False;
        cbPackageType.ItemIndex := 0;
        cbPackageType.SetFocus;
      end;
  end;
  cbPackageState.Height := cbFilterBy.Height;
  cbPackageState.Top := (pnTop.Height - cbPackageState.Height) div 2;
  cbPackageType.Height := cbFilterBy.Height;
  cbPackageType.Top := (pnTop.Height - cbPackageType.Height) div 2;
  cbPackageCategory.Height := cbFilterBy.Height;
  cbPackageCategory.Top := (pnTop.Height - cbPackageCategory.Height) div 2;
end;

procedure TMainFrm.cbPackageCategoryChange(Sender: TObject);
begin
  if cbPackageCategory.ItemIndex > 0 then
    VisualTree.FilterTree(TFilterBy(cbFilterBy.ItemIndex), 'PackageCategory', cbPackageCategory.ItemIndex - 1)
  else
    VisualTree.ResetFilter;
end;

procedure TMainFrm.cbPackageTypeChange(Sender: TObject);
begin
  if cbPackageType.ItemIndex > 0 then
    VisualTree.FilterTree(TFilterBy(cbFilterBy.ItemIndex), 'PackageType', cbPackageType.ItemIndex - 1)
  else
    VisualTree.ResetFilter;
end;

procedure TMainFrm.cbPackageStateChange(Sender: TObject);
begin
  if cbPackageState.ItemIndex > 0 then
    VisualTree.FilterTree(TFilterBy(cbFilterBy.ItemIndex), 'PackageState', cbPackageState.ItemIndex - 1)
  else
    VisualTree.ResetFilter;
end;

procedure TMainFrm.edFilterChange(Sender: TObject);
begin
  if edFilter.Text <> '' then
    VisualTree.FilterTree(TFilterBy(cbFilterBy.ItemIndex), edFilter.Text)
  else
    VisualTree.ResetFilter;
end;

procedure TMainFrm.pnTopResize(Sender: TObject);
begin
  cbFilterBy.Left := (pnTop.Width - pnFilter.Width - cbFilterBy.Width + lbFilterBy.Width - 5) div 2;
  pnFilter.Left := cbFilterBy.Left + cbFilterBy.Width + 5;
  cbPackageType.Left := pnFilter.Left;
  cbPackageState.Left := pnFilter.Left;
  cbPackageCategory.Left := pnFilter.Left;
  lbFilterBy.Left := cbFilterBy.Left - 8 - lbFilterBy.Width;
end;

procedure TMainFrm.spClearClick(Sender: TObject);
begin
  edFilter.OnChange := nil;
  edFilter.Text := '';
  VisualTree.ResetFilter;
  edFilter.OnChange := @edFilterChange;
end;

procedure TMainFrm.spExpandClick(Sender: TObject);
begin
  case TSpeedButton(Sender).Tag of
    1: VisualTree.ExpandEx;
    2: VisualTree.CollapseEx;
  end;
end;

procedure TMainFrm.tbOptionsClick(Sender: TObject);
begin
  ShowOptions;
end;

procedure TMainFrm.tbRefreshClick(Sender: TObject);
begin
  VisualTree.VST.Clear;
  VisualTree.VST.Invalidate;
  GetPackageList;
end;

procedure TMainFrm.tbDownloadClick(Sender: TObject);
var
  DstDir: String;
  CanGo: Boolean;
  DoExtract: Boolean;
  DoOpen: Boolean;
begin
  if not IsSomethingChecked then
    Exit;

  SDD.InitialDir := Options.LastDownloadDir;
  if SDD.Execute then
  begin
    CanGo := True;
    DstDir := AppendPathDelim(SDD.FileName);
    VisualTree.UpdatePackageStates;
    PackageListFrm := TPackageListFrm.Create(MainFrm);
    try
      PackageListFrm.lbMessage.Caption := rsMainFrmPackageAlreadyDownloaded;
      PackageListFrm.PopulateList(1, DstDir);
      if PackageListFrm.Count > 0 then
        CanGo := PackageListFrm.ShowModal = mrYes
      else
        CanGo := True;
    finally
      PackageListFrm.Free;
    end;
  end
  else
    CanGo := False;

  if CanGo then
  begin
    Options.LastDownloadDir := DstDir;
    Options.Changed := True;
    PackageAction := paDownloadTo;
    DoExtract := False;
    if Download(DstDir, DoExtract) = mrOK then
    begin
      if SerializablePackages.ExtractCount > 0 then
      begin
        if DoExtract then
        begin
          DoOpen := False;
          if Extract(DstDir, DstDir, DoOpen) = mrOk then
          begin
            if DoOpen then
              OpenDocument(DstDir);
          end;
        end;
      end;
    end;
  end;
  SerializablePackages.RemoveErrorState;
end;

procedure TMainFrm.tbUpdateClick(Sender: TObject);
var
  CanGo: Boolean;
  DoOpen: Boolean;
  DoExtract: Boolean;
  InstallStatus: TInstallStatus;
  NeedToRebuild: Boolean;
begin
  if not IsSomethingChecked(True) then
    Exit;
  if MessageDlgEx(rsMainFrmPackageUpdateWarning, mtConfirmation, [mbYes, mbNo], Self) = mrNo then
    Exit;
  CanGo := True;
  NeedToRebuild := False;
  VisualTree.UpdatePackageStates;
  PackageListFrm := TPackageListFrm.Create(MainFrm);
  try
    PackageListFrm.lbMessage.Caption := rsMainFrmPackageUpdate0;
    PackageListFrm.PopulateList(2);
    if PackageListFrm.Count > 0 then
      CanGo := PackageListFrm.ShowModal = mrYes
    else
      CanGo := True;
  finally
    PackageListFrm.Free;
  end;

  if CanGo then
  begin
    PackageAction := paUpdate;
    VisualTree.UpdatePackageStates;
    if SerializablePackages.DownloadCount > 0 then
    begin
      DoExtract := True;
      CanGo := UpdateP(Options.LocalRepositoryUpdate, DoExtract) = mrOK;
      VisualTree.UpdatePackageStates;
    end;

    if CanGo then
    begin
      if SerializablePackages.ExtractCount > 0 then
      begin
        DoOpen := False;
        CanGo := Extract(Options.LocalRepositoryUpdate, Options.LocalRepositoryPackages, DoOpen, True) = mrOk;
        VisualTree.UpdatePackageStates;
      end;

      if CanGo then
      begin
        if Options.DeleteZipAfterInstall then
          SerializablePackages.DeleteDownloadedZipFiles;
        if SerializablePackages.InstallCount > 0 then
        begin
          InstallStatus := isFailed;
          if Install(InstallStatus, NeedToRebuild) = mrOk then
          begin
            if (InstallStatus = isSuccess) or (InstallStatus = isPartiallyFailed) then
            begin
              SerializablePackages.MarkRuntimePackages;
              VisualTree.UpdatePackageStates;
              if NeedToRebuild then
              begin
                EnableDisableControls(False);
                IDECommands.ExecuteIDECommand(Self, ecBuildLazarus);
                EnableDisableControls(True);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  if not NeedToRebuild then
    SerializablePackages.RemoveErrorState;
end;

procedure TMainFrm.tbInstallClick(Sender: TObject);
var
  CanGo: Boolean;
  DoExtract: Boolean;
  DoOpen: Boolean;
  InstallStatus: TInstallStatus;
  NeedToRebuild: Boolean;
begin
  if not IsSomethingChecked then
    Exit;

  CanGo := True;
  VisualTree.UpdatePackageStates;
  PackageListFrm := TPackageListFrm.Create(MainFrm);
  try
    PackageListFrm.lbMessage.Caption := rsMainFrmPackageAlreadyInstalled;
    PackageListFrm.PopulateList(0);
    if PackageListFrm.Count > 0 then
      CanGo := PackageListFrm.ShowModal = mrYes
    else
      CanGo := True;
  finally
    PackageListFrm.Free;
  end;

  if CanGo then
  begin
    PackageAction := paInstall;
    VisualTree.UpdatePackageStates;
    if SerializablePackages.DownloadCount > 0 then
    begin
      DoExtract := True;
      CanGo := Download(Options.LocalRepositoryArchive, DoExtract) = mrOK;
      VisualTree.UpdatePackageStates;
    end;

    if CanGo then
    begin
      if SerializablePackages.ExtractCount > 0 then
      begin
        DoOpen := False;
        CanGo := Extract(Options.LocalRepositoryArchive, Options.LocalRepositoryPackages, DoOpen) = mrOk;
        VisualTree.UpdatePackageStates;
      end;

      if CanGo then
      begin
        if Options.DeleteZipAfterInstall then
          SerializablePackages.DeleteDownloadedZipFiles;
        if SerializablePackages.InstallCount > 0 then
        begin
          InstallStatus := isFailed;
          NeedToRebuild := False;
          if Install(InstallStatus, NeedToRebuild) = mrOk then
          begin
            SerializablePackages.MarkRuntimePackages;
            VisualTree.UpdatePackageStates;
            if (InstallStatus = isSuccess) or (InstallStatus = isPartiallyFailed) then
            begin
              if NeedToRebuild then
              begin
                EnableDisableControls(False);
                IDECommands.ExecuteIDECommand(Self, ecBuildLazarus);
                EnableDisableControls(True);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  if not NeedToRebuild then
    SerializablePackages.RemoveErrorState;
end;

procedure TMainFrm.tbCleanUpClick(Sender: TObject);
var
  Cnt: Integer;
begin
  if MessageDlgEx(rsRepositoryCleanup0, mtInformation, [mbYes, mbNo], Self) = mrYes then
  begin
    Cnt := SerializablePackages.Cleanup;
    MessageDlgEx(IntToStr(Cnt) + ' ' + rsRepositoryCleanup1, mtInformation, [mbOk], Self);
  end;
end;

procedure TMainFrm.pnToolBarResize(Sender: TObject);
var
  I: Integer;
  W: Integer;
begin
  W := 0;
  for I := 0 to tbButtons.ButtonCount - 1 do
    W := W + tbButtons.Buttons[I].Width;
  tbButtons.Width := W + 2;
  if tbButtons.Width < 450 then
    tbButtons.Width := 450;
  tbButtons.Left := (pnToolBar.Width - tbButtons.Width) div 2;
  tbButtons.Height := tbButtons.Buttons[0].Height;
  tbButtons.Top := (pnToolBar.Height - tbButtons.Height) div 2;
end;

procedure TMainFrm.miCreateRepositoryPackageClick(Sender: TObject);
begin
  CreateRepositoryPackagesFrm := TCreateRepositoryPackagesFrm.Create(MainFrm);
  try
   CreateRepositoryPackagesFrm.ShowModal;
  finally
    CreateRepositoryPackagesFrm.Free;
  end;
end;

procedure TMainFrm.pnMainResize(Sender: TObject);
begin
  pnMessage.Left := (pnMain.Width - pnMessage.Width) div 2;
  pnMessage.Top := (pnMain.Height - pnMessage.Height) div 2;
end;

procedure TMainFrm.miJSONShowClick(Sender: TObject);
begin
  if not mJSON.Visible then
  begin
    EnableDisableControls(False);
    mJSON.Visible := True;
    mJSON.BringToFront;
  end
  else
  begin
    mJSON.SendToBack;
    mJSON.Visible := False;
    EnableDisableControls(True);
  end;
end;

procedure TMainFrm.SetupControls;
begin
  cbFilterBy.Clear;
  cbFilterBy.Items.Add(rsMainFrmVSTHeaderColumnPackageName);
  cbFilterBy.Items.Add(rsMainFrmVSTHeaderColumnPackageFile);
  cbFilterBy.Items.Add(rsMainFrmVSTTextPackageCategory);
  cbFilterBy.Items.Add(rsMainFrmVSTTextPackageStatus);
  cbFilterBy.Items.Add(rsMainFrmVSTTextVersion);
  cbFilterBy.Items.Add(rsMainFrmVSTTextDescription);
  cbFilterBy.Items.Add(rsMainFrmVSTTextAuthor);
  cbFilterBy.Items.Add(rsMainFrmVSTTextLazCompatibility);
  cbFilterBy.Items.Add(rsMainFrmVSTTextFPCCompatibility);
  cbFilterBy.Items.Add(rsMainFrmVSTTextSupportedWidgetsets);
  cbFilterBy.Items.Add(rsMainFrmVSTTextPackagetype);
  cbFilterBy.Items.Add(rsMainFrmVSTTextDependecies);
  cbFilterBy.Items.Add(rsMainFrmVSTTextLicense);
  cbFilterBy.ItemIndex := 0;

  cbPackageType.Clear;
  cbPackageType.Items.Add('');
  cbPackageType.Items.Add(rsMainFrmVSTTextPackageType0);
  cbPackageType.Items.Add(rsMainFrmVSTTextPackageType1);
  cbPackageType.Items.Add(rsMainFrmVSTTextPackageType2);
  cbPackageType.Items.Add(rsMainFrmVSTTextPackageType3);

  cbPackageState.Clear;
  cbPackageState.Items.Add('');
  cbPackageState.Items.Add(rsMainFrmVSTTextPackageState0);
  cbPackageState.Items.Add(rsMainFrmVSTTextPackageState1);
  cbPackageState.Items.Add(rsMainFrmVSTTextPackageState2);
  cbPackageState.Items.Add(rsMainFrmVSTTextPackageState3);

  cbPackageCategory.Clear;
  cbPackageCategory.Items.Add('');
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory0);
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory1);
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory2);
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory3);
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory4);
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory5);
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory6);
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory7);
  cbPackageCategory.Items.Add(rsMainFrmVSTTextPackageCategory8);


  tbRefresh.Caption := rsMainFrmTBRefreshCaption;
  tbRefresh.Hint := rsMainFrmTBRefreshHint;
  tbDownload.Caption := rsMainFrmTBDownloadCaption;
  tbDownload.Hint := rsMainFrmTBDownloadHint;
  tbInstall.Caption := rsMainFrmTBInstallCaption;
  tbInstall.Hint := rsMainFrmTBInstallHint;
  tbUpdate.Caption := rsMainFrmTBUpdateCaption;
  tbUpdate.Hint := rsMainFrmTBUpdateHint;
  tbCleanUp.Caption := rsMainFrmTBCleanUpCaption;
  tbCleanUp.Hint := rsMainFrmTBCleanUpHint;
  tbCreate.Caption := rsMainFrmTBRepositoryCaption;
  tbCreate.Hint := rsMainFrmTBRepositoryHint;
  tbOptions.Caption := rsMainFrmTBOptionsCaption;
  tbOptions.Hint := rsMainFrmTBOptionsHint;
  miCreateRepositoryPackage.Caption := rsMainFrmmiCreateRepositoryPackage;
  miCreateRepository.Caption := rsMainFrmmiCreateRepository;
  miJSONShow.Caption := rsMainFrmmiJSONShow;
  miJSONHide.Caption := rsMainFrmmiJSONHide;

  Caption := rsMainFrmCaption;
  edFilter.Hint := rsMainFrmedFilterHint;
  spClear.Hint := rsMainFrmspClearHint;
  cbFilterBy.Top := (pnTop.Height - cbFilterBy.Height) div 2;
  pnFilter.Height := cbFilterBy.Height;
  pnFilter.Top := (pnTop.Height - pnFilter.Height) div 2;
  cbPackageState.Top := (pnTop.Height - cbPackageState.Height) div 2;
  cbPackageType.Top := (pnTop.Height - cbPackageType.Height) div 2;
  cbPackageCategory.Top := (pnTop.Height - cbPackageCategory.Height) div 2;
  cbAll.Top := (pnTop.Height - cbAll.Height) div 2;
  cbAll.Hint := rsMainFrmcbAllHint;
  spExpand.Top:= (pnTop.Height - spExpand.Height + 1) div 2;
  spExpand.Hint := rsMainFrmspExpandHint;
  spCollapse.Top:= (pnTop.Height - spCollapse.Height + 1) div 2;
  spCollapse.Hint := rsMainFrmspCollapseHint;
  cbAll.Caption := rsMainFrmcbAllCaption;
  lbFilterBy.Top := cbFilterBy.Top + (cbFilterBy.Height - lbFilterBy.Height) div 2;
  lbFilterBy.Caption := rsMainFrmlbFilterCaption;
  cbFilterBy.Hint := rsMainFrmcbFilterByHint;

  cbPackageCategory.Visible := False;
  cbPackageType.Visible := False;
  cbPackageState.Visible := False;
end;

end.
















