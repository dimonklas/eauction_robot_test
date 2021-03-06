*** Settings ***
Library  openprocurement_client_helper.py
Library  openprocurement_client.utils


*** Keywords ***
Отримати internal id по UAid
  [Arguments]  ${username}  ${tender_uaid}
  Log  ${username}
  Log  ${tender_uaid}
  Log Many  ${USERS.users['${username}'].id_map}
  ${status}=  Run Keyword And Return Status  Dictionary Should Contain Key  ${USERS.users['${username}'].id_map}  ${tender_uaid}
  Run Keyword And Return If  ${status}  Get From Dictionary  ${USERS.users['${username}'].id_map}  ${tender_uaid}
  ${tender_id}=  Wait Until Keyword Succeeds  5x  30 sec  get_tender_id_by_uaid  ${tender_uaid}  ${USERS.users['${username}'].public_client}  id_field=auctionID
  Set To Dictionary  ${USERS.users['${username}'].id_map}  ${tender_uaid}  ${tender_id}
  [return]  ${tender_id}


Підготувати клієнт для користувача
  [Arguments]  ${username}
  [Documentation]  Відкрити браузер, створити об’єкти api wrapper і
  ...              ds api wrapper, приєднати їх атрибутами до користувача, тощо
  Log  ${resource}
  Log  ${api_host_url}
  Log  ${api_version}
  Log  ${ds_host_url}
  ${auth_ds_all}=  get variable value  ${USERS.users.${username}.auth_ds}
  ${auth_ds}=  set variable  ${auth_ds_all.${resource}}
  Log  ${auth_ds}

#  Uncomment this line if there is need to precess files operations without DS.
#  ${ds_api_wraper}=  set variable  ${None}
  ${ds_api_wraper}=  prepare_ds_api_wrapper  ${ds_host_url}  ${auth_ds}

  ${api_wrapper}=  prepare_api_wrapper  ${USERS.users['${username}'].api_key}  ${resource}  ${api_host_url}  ${api_version}  ${ds_api_wraper}
  ${api_public_wrapper}=  prepare_api_wrapper  ${USERS.users['${username}'].api_key}  ${resource}  ${api_host_public_url}  ${api_version}  ${ds_api_wraper}
  Set To Dictionary  ${USERS.users['${username}']}  client=${api_wrapper}
  Set To Dictionary  ${USERS.users['${username}']}  public_client=${api_public_wrapper}
  Set To Dictionary  ${USERS.users['${username}']}  access_token=${EMPTY}
  ${id_map}=  Create Dictionary
  Set To Dictionary  ${USERS.users['${username}']}  id_map=${id_map}
  Log Variables


Завантажити документ
  [Arguments]  ${username}  ${filepath}  ${tender_uaid}
  Log  ${username}
  Log  ${tender_uaid}
  Log  ${filepath}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  upload_document  ${filepath}  ${tender}
  Log object data  ${reply}  reply
  [return]  ${reply}


Внести зміни в документ
  [Arguments]  ${username}  ${tender_uaid}  ${patch_data}
  Log  ${patch_data}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_document  ${tender}  ${patch_data}
  [return]  ${reply}


Завантажити ілюстрацію
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  openprocurement_client.Завантажити документ в тендер з типом  ${username}  ${tender_uaid}  ${filepath}  documentType=illustration


Завантажити документ в тендер з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${documentType}
  ${document}=  openprocurement_client.Завантажити документ  ${username}  ${filepath}  ${tender_uaid}
  Keep In Dictionary  ${document['data']}  id
  Log  ${document}
  Set To Dictionary  ${document['data']}  documentType=${documentType}
  Log  ${document}
  ${reply}=  openprocurement_client.Внести зміни в документ  ${username}  ${tender_uaid}  ${document}
  Log  ${reply}
  [return]  ${reply}


Завантажити фінансову ліцензію
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}
  openprocurement_client.Завантажити документ в ставку з типом  ${username}  ${tender_uaid}  ${filepath}  documentType=financialLicense


Завантажити протокол аукціону
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${award_index}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${award_id}=  Get Variable Value  ${tender.data.awards[${award_index}].id}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${response}=  Call Method  ${USERS.users['${username}'].client}  upload_award_document  ${filepath}  ${tender}  ${award_id}  documents
  Keep In Dictionary  ${response['data']}  id
  Set To Dictionary  ${response['data']}  documentType=auctionProtocol
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_award_document  ${tender}  ${response}  ${award_id}  ${response['data'].id}
  Log  ${reply}
  [return]  ${reply}


Завантажити документ в ставку з типом
  [Arguments]  ${username}  ${tender_uaid}  ${filepath}  ${documentType}
  ${document}=  openprocurement_client.Завантажити документ в ставку  ${username}  ${filepath}  ${tender_uaid}
  Keep In Dictionary  ${document['upload_response']['data']}  id
  Log  ${document}
  Set To Dictionary  ${document['upload_response']['data']}  documentType=${documentType}
  Log  ${document}
  ${reply}=  openprocurement_client.Змінити документацію в ставці  ${username}  ${tender_uaid}  ${document['upload_response']}  ${document['upload_response']['data'].id}
  Log  ${reply}
  [return]  ${reply}


Додати Virtual Data Room
  [Arguments]  ${username}  ${tender_uaid}  ${vdr_url}  ${title}=Sample Virtual Data Room
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${doc_data}=  Create Dictionary  documentType=virtualDataRoom  url=${vdr_url}  title=${title}
  ${doc_data}=  Create Dictionary  data=${doc_data}
  Call Method  ${USERS.users['${username}'].client}  create_thin_document  ${tender}  ${doc_data}


Додати публічний паспорт активу
  [Arguments]  ${username}  ${tender_uaid}  ${certificate_url}  ${title}=Public Asset Certificate
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${doc_data}=  Create Dictionary  documentType=x_dgfPublicAssetCertificate  url=${certificate_url}  title=${title}
  ${doc_data}=  Create Dictionary  data=${doc_data}
  Call Method  ${USERS.users['${username}'].client}  create_thin_document  ${tender}  ${doc_data}


Додати офлайн документ
  [Arguments]  ${username}  ${tender_uaid}  ${accessDetails}  ${title}=Familiarization with bank asset
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${doc_data}=  Create Dictionary  documentType=x_dgfAssetFamiliarization  accessDetails=${accessDetails}  title=${title}
  ${doc_data}=  Create Dictionary  data=${doc_data}
  Call Method  ${USERS.users['${username}'].client}  create_thin_document  ${tender}  ${doc_data}


Отримати інформацію із документа
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${document}=  get_document_by_id  ${tender.data}  ${doc_id}
  Log  ${document}
  [Return]  ${document['${field}']}


Отримати інформацію із документа по індексу
  [Arguments]  ${username}  ${tender_uaid}  ${document_index}  ${field}
  ${status}  ${field_value}=  Run keyword and ignore error
  ...      Отримати дані із тендера
  ...      ${username}
  ...      ${tender_uaid}
  ...      documents[${document_index}].${field}
  ${error_message}=  Convert To String  ${field_value}
  ${field_value}=  Set Variable If
  ...      "Field not found" in "${error_message}"
  ...      ${None}
  ...      ${field_value}
  Log  ${field_value}
  [return]  ${field_value}


Отримати документ
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${document}=  get_document_by_id  ${tender.data}  ${doc_id}
  ${filename}=  download_file_from_url  ${document.url}  ${OUTPUT_DIR}${/}${document.title}
  [return]  ${filename}


Отримати посилання на аукціон для глядача
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${auctionUrl}=  Run Keyword IF  '${lot_id}'  Set Variable  ${tender.data.lots[${lot_index}].auctionUrl}
  ...                         ELSE  Set Variable  ${tender.data.auctionUrl}
  [return]  ${auctionUrl}

##############################################################################
#             Tender operations
##############################################################################

Підготувати дані для оголошення тендера
  [Documentation]  Це слово використовується в майданчиків, тому потрібно, щоб воно було і тут
  [Arguments]  ${username}  ${tender_data}  ${role_name}
  [return]  ${tender_data}


Створити тендер
  [Arguments]  ${username}  ${tender_data}
  ${tender}=  Call Method  ${USERS.users['${username}'].client}  create_tender  ${tender_data}
  Log object data  ${tender}  created_tender
  ${access_token}=  Get Variable Value  ${tender.access.token}
  Set To Dictionary  ${USERS.users['${username}']}   access_token=${access_token}
  Set To Dictionary  ${USERS.users['${username}']}   tender_data=${tender}
  Log  ${\n}${API_HOST_URL}/api/${API_VERSION}/auctions/${tender.data.id}${\n}  WARN
  Log   ${USERS.users['${username}'].tender_data}
  [return]  ${tender.data.auctionID}


Пошук тендера по ідентифікатору
  [Arguments]  ${username}  ${tender_uaid}
  ${internalid}=  openprocurement_client.Отримати internal id по UAid  ${username}  ${tender_uaid}
  ${tender}=  Call Method  ${USERS.users['${username}'].public_client}  get_tender  ${internalid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  Set To Dictionary  ${USERS.users['${username}']}  tender_data=${tender}
  ${tender}=  munch_dict  arg=${tender}
  Log  ${tender}
  [return]   ${tender}


Оновити сторінку з тендером
  [Arguments]  ${username}  ${tender_uaid}
  openprocurement_client.Пошук тендера по ідентифікатору    ${username}  ${tender_uaid}


Отримати інформацію із тендера
  [Arguments]  ${username}  ${tender_uaid}  ${field_name}
  openprocurement_client.Пошук тендера по ідентифікатору
  ...      ${username}
  ...      ${tender_uaid}

  ${status}  ${field_value}=  Run keyword and ignore error
  ...      Get from object
  ...      ${USERS.users['${username}'].tender_data.data}
  ...      ${field_name}
  Run Keyword if  '${status}' == 'PASS'  Return from keyword   ${field_value}

  Fail  Field not found: ${field_name}


Внести зміни в тендер
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${prev_value} =  Отримати дані із тендера  ${username}  ${tender_uaid}  ${fieldname}
  Set_To_Object  ${tender.data}   ${fieldname}   ${fieldvalue}
  ${procurementMethodType}=  Get From Object  ${tender.data}  procurementMethodType
  Run Keyword If  '${procurementMethodType}' == 'aboveThresholdUA' or '${procurementMethodType}' == 'aboveThresholdEU'
  ...      Remove From Dictionary  ${tender.data}  enquiryPeriod
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${tender}=  Call Method  ${USERS.users['${username}'].client}  patch_tender  ${tender}
  Run Keyword And Expect Error  *  Порівняти об'єкти  ${prev_value}  ${tender.data.${fieldname}}
  Set_To_Object   ${USERS.users['${username}'].tender_data}   ${fieldname}   ${fieldvalue}


Отримати кількість документів в тендері
  [Arguments]  ${username}  ${tender_uaid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${status}  ${number_of_documents}=  Run keyword and ignore error
  ...      Get Length
  ...      ${tender.data.documents}
  ${error_message}=  Convert To String  ${number_of_documents}
  ${number_of_documents}=  Set Variable If
  ...      "AttributeError" in "${error_message}" or "KeyError" in "${error_message}"
  ...      ${0}
  ...      ${number_of_documents}
  Log  ${number_of_documents}
  [return]  ${number_of_documents}

##############################################################################
#             Item operations
##############################################################################

Додати предмет закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${item}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  Append To List  ${tender.data['items']}  ${item}
  Call Method  ${USERS.users['${username}'].client}  patch_tender  ${tender}


Отримати інформацію із предмету
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${field_name}
  ${field_name}=  Отримати шлях до поля об’єкта  ${username}  ${field_name}  ${item_id}
  Run Keyword And Return  openprocurement_client.Отримати інформацію із тендера  ${username}  ${tender_uaid}  ${field_name}


Видалити предмет закупівлі
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${lot_id}=${Empty}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${item_index}=  get_object_index_by_id  ${tender.data['items']}  ${item_id}
  Remove From List  ${tender.data['items']}  ${item_index}
  Call Method  ${USERS.users['${username}'].client}  patch_tender  ${tender}


Отримати кількість предметів в тендері
  [Arguments]  ${username}  ${tender_uaid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${status}  ${number_of_items}=  Run keyword and ignore error
  ...      Get Length
  ...      ${tender.data['items']}
  ${error_message}=  Convert To String  ${number_of_items}
  ${number_of_items}=  Set Variable If
  ...      "AttributeError" in "${error_message}" or "KeyError" in "${error_message}"
  ...      ${0}
  ...      ${number_of_items}
  Log  ${number_of_items}
  [return]  ${number_of_items}

##############################################################################
#             Questions
##############################################################################

Задати запитання на предмет
  [Arguments]  ${username}  ${tender_uaid}  ${item_id}  ${question}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${item_index}=  get_object_index_by_id  ${tender.data['items']}  ${item_id}
  ${item_id}=  Get Variable Value  ${tender.data['items'][${item_index}].id}
  ${question}=  test_related_question  ${question}  item  ${item_id}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  create_question  ${tender}  ${question}
  [return]  ${reply}

Задати запитання на тендер
  [Arguments]  ${username}  ${tender_uaid}  ${question}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  create_question  ${tender}  ${question}
  [return]  ${reply}


Отримати інформацію із запитання
  [Arguments]  ${username}  ${tender_uaid}  ${question_id}  ${field_name}
  ${field_name}=  Отримати шлях до поля об’єкта  ${username}  ${field_name}  ${question_id}
  Run Keyword And Return  openprocurement_client.Отримати інформацію із тендера  ${username}  ${tender_uaid}  ${field_name}


Відповісти на запитання
  [Arguments]  ${username}  ${tender_uaid}  ${answer_data}  ${question_id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${answer_data.data.id}=  openprocurement_client.Отримати інформацію із запитання  ${username}  ${tender_uaid}  ${question_id}  id
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_question  ${tender}  ${answer_data}
  [return]  ${reply}

##############################################################################
#             Bid operations
##############################################################################

Подати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${bid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  create_bid  ${tender}  ${bid}
  Log  ${reply}
  Set To Dictionary  ${reply['data']}  status=active
  ${reply_active}=  Call Method  ${USERS.users['${username}'].client}  patch_bid  ${tender}  ${reply}
  Set To Dictionary  ${USERS.users['${username}']}  access_token=${reply['access']['token']}
  Set To Dictionary   ${USERS.users['${username}'].bidresponses['bid'].data}  id=${reply['data']['id']}
  Log  ${reply_active}
  Set To Dictionary  ${USERS.users['${username}']}  bid_id=${reply['data']['id']}
  [return]  ${reply}


Змінити цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}  ${fieldname}  ${fieldvalue}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${bid}=  openprocurement_client.Отримати пропозицію  ${username}  ${tender_uaid}
  Set_To_Object  ${bid.data}   ${fieldname}   ${fieldvalue}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_bid  ${tender}  ${bid}
  Log  ${reply}
  [return]   ${reply}


Скасувати цінову пропозицію
  [Arguments]  ${username}  ${tender_uaid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${bid_id}=  openprocurement_client.Отримати інформацію із пропозиції  ${username}  ${tender_uaid}  id
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  delete_bid   ${tender}  ${bid_id}  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  Log  ${reply}
  [return]   ${reply}


Завантажити документ в ставку
  [Arguments]  ${username}  ${path}  ${tender_uaid}  ${doc_type}=documents
  ${bid_id}=  Get Variable Value   ${USERS.users['${username}'].bidresponses['resp'].data.id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  ${response}=  Call Method  ${USERS.users['${username}'].client}  upload_bid_document  ${path}  ${tender}  ${bid_id}  ${doc_type}
  ${uploaded_file} =  Create Dictionary   filepath=${path}   upload_response=${response}
  Log object data   ${uploaded_file}
  [return]  ${uploaded_file}


Змінити документ в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${path}  ${docid}  ${doc_type}=documents
  ${bid_id}=  Get Variable Value   ${USERS.users['${username}'].bidresponses['resp'].data.id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  ${response}=  Call Method  ${USERS.users['${username}'].client}  update_bid_document  ${path}  ${tender}   ${bid_id}   ${docid}  ${doc_type}
  ${uploaded_file} =  Create Dictionary   filepath=${path}   upload_response=${response}
  Log object data   ${uploaded_file}
  [return]  ${uploaded_file}


Змінити документацію в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${doc_data}  ${docid}
  ${bid_id}=  Get Variable Value   ${USERS.users['${username}'].bidresponses['resp'].data.id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].bidresponses['resp'].access.token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_bid_document   ${tender}   ${doc_data}   ${bid_id}   ${docid}
  [return]  ${reply}


Отримати пропозицію
  [Arguments]  ${username}  ${tender_uaid}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${bid_id}=  Get Variable Value  ${USERS.users['${username}'].bid_id}
  ${token}=  Get Variable Value  ${USERS.users['${username}'].access_token}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  get_bid  ${tender}  ${bid_id}  ${token}
  ${reply}=  munch_dict  arg=${reply}
  [return]  ${reply}


Отримати інформацію із пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${field}
  ${bid}=  openprocurement_client.Отримати пропозицію  ${username}  ${tender_uaid}
  [return]  ${bid.data.${field}}


Отримати дані із документу пропозиції
  [Arguments]  ${username}  ${tender_uaid}  ${bid_index}  ${document_index}  ${field}
  ${status}  ${field_value}=  Run keyword and ignore error
  ...      Отримати дані із тендера
  ...      ${username}
  ...      ${tender_uaid}
  ...      bids[${bid_index}].documents[${document_index}].${field}
  ${error_message}=  Convert To String  ${field_value}
  ${field_value}=  Set Variable If
  ...      "Field not found" in "${error_message}"
  ...      ${None}
  ...      ${field_value}
  Log  ${field_value}
  [return]  ${field_value}


Отримати посилання на аукціон для учасника
  [Arguments]  ${username}  ${tender_uaid}  ${lot_id}=${Empty}
  ${bid}=  openprocurement_client.Отримати пропозицію  ${username}  ${tender_uaid}
  ${participationUrl}=  Run Keyword IF  '${lot_id}'  Set Variable  ${bid.data.lotValues[${lot_index}].participationUrl}
  ...                         ELSE  Set Variable  ${bid.data.participationUrl}
  [return]  ${participationUrl}


Отримати кількість документів в ставці
  [Arguments]  ${username}  ${tender_uaid}  ${bid_index}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${status}  ${number_of_documents}=  Run keyword and ignore error
  ...      Get Length
  ...      ${tender.data.bids[${bid_index}].documents}
  ${error_message}=  Convert To String  ${number_of_documents}
  ${number_of_documents}=  Set Variable If
  ...      "AttributeError" in "${error_message}" or "KeyError" in "${error_message}"
  ...      ${0}
  ...      ${number_of_documents}
  Log  ${number_of_documents}
  [return]  ${number_of_documents}

##############################################################################
#             Qualification operations
##############################################################################

Завантажити документ рішення кваліфікаційної комісії
  [Documentation]
  ...      [Arguments] Username, tender uaid, qualification number and document to upload
  ...      [Description] Find tender using uaid,  and call upload_qualification_document
  ...      [Return] Reply of API
  [Arguments]  ${username}  ${document}  ${tender_uaid}  ${award_num}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${doc}=  Call Method  ${USERS.users['${username}'].client}  upload_award_document  ${document}  ${tender}  ${tender.data.awards[${award_num}].id}
  Log  ${doc}
  [Return]  ${doc}


Підтвердити постачальника
  [Documentation]
  ...      [Arguments] Username, tender uaid and number of the award to confirm
  ...      Find tender using uaid, create dict with confirmation data and call patch_award
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${award}=  create_data_dict  data.status  active
  Set To Dictionary  ${award.data}  id=${tender.data.awards[${award_num}].id}
  Run Keyword IF  'open' in '${MODE}'
  ...      Set To Dictionary  ${award.data}
  ...      qualified=${True}
  ...      eligible=${True}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_award  ${tender}  ${award}
  Log  ${reply}


Підтвердити наявність протоколу аукціону
  [Documentation]
  ...      [Arguments] Username, tender uaid and number of the award to confirm
  ...      Find tender using uaid, create dict with confirmation data and call patch_award
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${award_index}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${award}=  create_data_dict  data.status  pending.payment
  Set To Dictionary  ${award.data}  id=${tender.data.awards[${award_index}].id}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_award  ${tender}  ${award}
  Log  ${reply}


Дискваліфікувати постачальника
  [Documentation]
  ...      [Arguments] Username, tender uaid and award number
  ...      [Description] Find tender using uaid, create data dict with unsuccessful status and call patch_award
  ...      [Return] Reply of API
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}  ${description}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${title}=  Set Variable  Disqualified
  ${award}=  create_data_dict   data.status  unsuccessful
  Set To Dictionary  ${award.data}  id=${tender.data.awards[${award_num}].id}
  Set To Dictionary  ${award.data}  description=${description}
  Set To Dictionary  ${award.data}  title=${title}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_award  ${tender}  ${award}
  Log  ${reply}
  [Return]  ${reply}


Скасування рішення кваліфікаційної комісії
  [Documentation]
  ...      [Arguments] Username, tender uaid and award number
  ...      [Description] Find tender using uaid, create data dict with unsuccessful status and call patch_award
  ...      [Return] Reply of API
  [Arguments]  ${username}  ${tender_uaid}  ${award_num}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${award}=  create_data_dict   data.status  cancelled
  Set To Dictionary  ${award.data}  id=${tender.data.awards[${award_num}].id}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_award  ${tender}  ${award}
  Log  ${reply}
  [Return]  ${reply}

##############################################################################
#             Limited procurement
##############################################################################

Створити постачальника, додати документацію і підтвердити його
  [Documentation]
  ...      [Arguments] Username, tender uaid and supplier data
  ...      Find tender using uaid and call create_award, add documentation to that award and update his status to active
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${supplier_data}  ${document}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  create_award  ${tender}  ${supplier_data}
  Log  ${reply}
  ${supplier_number}=  Set variable  0
  openprocurement_client.Завантажити документ рішення кваліфікаційної комісії  ${username}  ${document}  ${tender_uaid}  ${supplier_number}
  openprocurement_client.Підтвердити постачальника  ${username}  ${tender_uaid}  ${supplier_number}


Скасувати закупівлю
  [Documentation]
  ...      [Arguments] Username, tender uaid, cancellation reason,
  ...      document and new description of document
  ...      [Description] Find tender using uaid, set cancellation reason, get data from cancel_tender
  ...      and call create_cancellation
  ...      After that add document to cancellation and change description of document
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${cancellation_reason}  ${document}  ${new_description}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${data}=  Create dictionary  reason=${cancellation_reason}
  ${cancellation_data}=  Create dictionary  data=${data}
  ${cancellation_data}=  munch_dict  arg=${cancellation_data}
  ${cancel_reply}=  Call Method  ${USERS.users['${username}'].client}  create_cancellation  ${tender}  ${cancellation_data}
  ${cancellation_id}=  Set variable  ${cancel_reply.data.id}

  ${document_id}=  openprocurement_client.Завантажити документацію до запиту на скасування  ${username}  ${tender_uaid}  ${cancellation_id}  ${document}

  openprocurement_client.Змінити опис документа в скасуванні  ${username}  ${tender_uaid}  ${cancellation_id}  ${document_id}  ${new_description}

  openprocurement_client.Підтвердити скасування закупівлі  ${username}  ${tender_uaid}  ${cancellation_id}


Завантажити документацію до запиту на скасування
  [Documentation]
  ...      [Arguments] Username, tender uaid, cancellation id and document to upload
  ...      [Description] Find tender using uaid, and call upload_cancellation_document
  ...      [Return] ID of added document
  [Arguments]  ${username}  ${tender_uaid}  ${cancellation_id}  ${document}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${doc_reply}=  Call Method  ${USERS.users['${username}'].client}  upload_cancellation_document  ${document}  ${tender}  ${cancellation_id}
  Log  ${doc_reply}
  [Return]  ${doc_reply.data.id}


Змінити опис документа в скасуванні
  [Documentation]
  ...      [Arguments] Username, tender uaid, cancellation id, document id and new description of document
  ...      [Description] Find tender using uaid, create dict with data about description and call
  ...      patch_cancellation_document
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${cancellation_id}  ${document_id}  ${new_description}
  ${field}=  Set variable  description
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${temp}=  Create Dictionary  ${field}=${new_description}
  ${data}=  Create Dictionary  data=${temp}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_cancellation_document  ${tender}  ${data}  ${cancellation_id}  ${document_id}
  Log  ${reply}


Підтвердити скасування закупівлі
  [Documentation]
  ...      [Arguments] Username, tender uaid, cancellation number
  ...      Find tender using uaid, get cancellation test_confirmation data and call patch_cancellation
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${cancel_id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${data}=  test_confirm_data  ${cancel_id}
  Log  ${data}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_cancellation  ${tender}  ${data}
  Log  ${reply}


Отримати інформацію із документа до скасування
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}  ${field_name}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${document}=  get_document_by_id  ${tender.data}  ${doc_id}
  Log  ${document}
  [Return]  ${document['${field_name}']}


Отримати документ до скасування
  [Arguments]  ${username}  ${tender_uaid}  ${doc_id}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${document}=  get_document_by_id  ${tender.data}  ${doc_id}
  ${filename}=  download_file_from_url  ${document.url}  ${OUTPUT_DIR}${/}${document.title}
  [return]  ${filename}


Вказати дату отримання оплати
  [Arguments]  ${username}  ${tender_uaid}  ${contract_index}  ${fieldvalue}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${contract}=  Create Dictionary  data=${tender.data.contracts[${contract_index}]}
  Set To Dictionary  ${contract.data}  datePaid=${fieldvalue}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_contract  ${tender}  ${contract}
  Log  ${reply}


Підтвердити підписання контракту
  [Documentation]
  ...      [Arguments] Username, tender uaid, contract number
  ...      Find tender using uaid, get contract test_confirmation data and call patch_contract
  ...      [Return] Nothing
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${data}=  test_confirm_data  ${tender['data']['contracts'][${contract_num}]['id']}
  Log  ${data}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_contract  ${tender}  ${data}
  Log  ${reply}


Завантажити угоду до тендера
  [Arguments]  ${username}  ${tender_uaid}  ${contract_num}  ${filepath}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${contract_id}=  Get Variable Value  ${tender['data']['contracts'][${contract_num}]['id']}
  ${tender}=  set_access_key  ${tender}  ${USERS.users['${username}'].access_token}
  ${response}=  Call Method  ${USERS.users['${username}'].client}  upload_contract_document  ${filepath}  ${tender}  ${contract_id}  documents
  Keep In Dictionary  ${response['data']}  id
  Set To Dictionary  ${response['data']}  documentType=contractSigned
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_contract_document  ${tender}  ${response}  ${contract_id}  ${response['data'].id}
  Log  ${reply}
  [return]  ${reply}


##############################################################################
#             OpenUA procedure
##############################################################################

Підтвердити кваліфікацію
  [Documentation]
  ...      [Arguments] Username, tender uaid and qualification number
  ...      [Description] Find tender using uaid, create data dict with active status and call patch_qualification
  ...      [Return] Reply of API
  [Arguments]  ${username}  ${tender_uaid}  ${qualification_num}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${qualification}=  create_data_dict   data.status  active
  Set To Dictionary  ${qualification.data}  id=${tender.data.qualifications[${qualification_num}].id}  eligible=${True}  qualified=${True}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_qualification  ${tender}  ${qualification}
  Log  ${reply}
  [Return]  ${reply}


Відхилити кваліфікацію
  [Documentation]
  ...      [Arguments] Username, tender uaid and qualification number
  ...      [Description] Find tender using uaid, create data dict with unsuccessful status and call patch_qualification
  ...      [Return] Reply of API
  [Arguments]  ${username}  ${tender_uaid}  ${qualification_num}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${qualification}=  create_data_dict   data.status  unsuccessful
  Set To Dictionary  ${qualification.data}  id=${tender.data.qualifications[${qualification_num}].id}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_qualification  ${tender}  ${qualification}
  Log  ${reply}
  [Return]  ${reply}


Завантажити документ у кваліфікацію
  [Documentation]
  ...      [Arguments] Username, tender uaid, qualification number and document to upload
  ...      [Description] Find tender using uaid,  and call upload_qualification_document
  ...      [Return] Reply of API
  [Arguments]  ${username}  ${document}  ${tender_uaid}  ${qualification_num}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${doc_reply}=  Call Method  ${USERS.users['${username}'].client}  upload_qualification_document  ${document}  ${tender}  ${tender.data.qualifications[${qualification_num}].id}
  Log  ${doc_reply}
  [Return]  ${doc_reply}


Скасувати кваліфікацію
  [Documentation]
  ...      [Arguments] Username, tender uaid and qualification number
  ...      [Description] Find tender using uaid, create data dict with cancelled status and call patch_qualification
  ...      [Return] Reply of API
  [Arguments]  ${username}  ${tender_uaid}  ${qualification_num}
  ${tender}=  openprocurement_client.Пошук тендера по ідентифікатору  ${username}  ${tender_uaid}
  ${qualification}=  create_data_dict   data.status  cancelled
  Set To Dictionary  ${qualification.data}  id=${tender.data.qualifications[${qualification_num}].id}
  ${reply}=  Call Method  ${USERS.users['${username}'].client}  patch_qualification  ${tender}  ${qualification}
  Log  ${reply}
  [Return]  ${reply}
